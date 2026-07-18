"""RTMPose WholeBody adapter using MMPose (primary production pose engine)."""

from __future__ import annotations

import threading
import time
from pathlib import Path
from typing import Any

import cv2
import numpy as np

from app.domain.landmarks import (
    COCO_WHOLEBODY_KEYPOINT_NAMES,
    CORE_BODY_INDICES,
)
from app.services.pose_estimator import (
    Keypoint,
    PoseEstimate,
    PoseEstimator,
    PoseEstimatorError,
)

# Process-wide singleton so we never reload weights per frame/request.
_MODEL_LOCK = threading.RLock()
_MODEL_CACHE: dict[str, Any] = {}


def _cache_key(config_path: Path, checkpoint_path: Path, device: str) -> str:
    return f"{config_path.resolve()}::{checkpoint_path.resolve()}::{device}"


class RTMPoseWholeBodyAdapter(PoseEstimator):
    """MMPose top-down RTMPose WholeBody (133 keypoints)."""

    DEFAULT_MODEL_NAME = "rtmpose-m-wholebody"
    DEFAULT_MODEL_VERSION = "mmpose-1.3.2-rtmpose-m-coco-wholebody-256x192"

    def __init__(
        self,
        *,
        config_path: str | Path,
        checkpoint_path: str | Path,
        device: str = "cpu",
        inference_input_size: tuple[int, int] = (192, 256),  # (w, h) MMPose convention
    ) -> None:
        self._config_path = Path(config_path)
        self._checkpoint_path = Path(checkpoint_path)
        self._device = device
        self._inference_input_size = list(inference_input_size)
        self._model = None

    @property
    def model_name(self) -> str:
        return self.DEFAULT_MODEL_NAME

    @property
    def model_version(self) -> str:
        return f"{self.DEFAULT_MODEL_VERSION}:{self._checkpoint_path.name}"

    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self) -> None:
        if not self._config_path.is_file():
            raise PoseEstimatorError(
                "POSE_CONFIG_MISSING",
                f"RTMPose config not found: {self._config_path}",
            )
        if not self._checkpoint_path.is_file():
            raise PoseEstimatorError(
                "POSE_MODEL_MISSING",
                f"RTMPose checkpoint not found: {self._checkpoint_path}. "
                "Run scripts/download_rtmpose.py",
            )

        key = _cache_key(self._config_path, self._checkpoint_path, self._device)
        with _MODEL_LOCK:
            if key in _MODEL_CACHE:
                self._model = _MODEL_CACHE[key]
                return
            try:
                from mmpose.apis import init_model
            except Exception as exc:  # noqa: BLE001
                raise PoseEstimatorError(
                    "MMPOSE_UNAVAILABLE",
                    f"MMPose import failed: {exc}",
                    retriable=False,
                ) from exc

            try:
                model = init_model(
                    str(self._config_path),
                    str(self._checkpoint_path),
                    device=self._device,
                )
            except Exception as exc:  # noqa: BLE001
                raise PoseEstimatorError(
                    "POSE_MODEL_LOAD_FAILED",
                    f"Failed to load RTMPose WholeBody: {exc}",
                    retriable=True,
                ) from exc

            _MODEL_CACHE[key] = model
            self._model = model

    def estimate_crop(
        self,
        image_bgr: Any,
        *,
        crop_xyxy: list[float],
        video_id: str,
        job_id: str,
        frame_number: int,
        timestamp_ms: float,
        swimmer_track_id: str | None,
        min_keypoint_confidence: float,
        min_visible_core_joints: int,
    ) -> PoseEstimate:
        if self._model is None:
            self.load()

        started = time.perf_counter()
        if image_bgr is None or getattr(image_bgr, "size", 0) == 0:
            return self._unusable(
                video_id=video_id,
                job_id=job_id,
                frame_number=frame_number,
                timestamp_ms=timestamp_ms,
                swimmer_track_id=swimmer_track_id,
                crop_xyxy=crop_xyxy,
                reason="invalid_image",
                duration_ms=(time.perf_counter() - started) * 1000.0,
            )

        h, w = image_bgr.shape[:2]
        x1, y1, x2, y2 = [float(v) for v in crop_xyxy]
        x1 = max(0.0, min(float(w - 1), x1))
        y1 = max(0.0, min(float(h - 1), y1))
        x2 = max(0.0, min(float(w), x2))
        y2 = max(0.0, min(float(h), y2))
        if x2 - x1 < 2 or y2 - y1 < 2:
            return self._unusable(
                video_id=video_id,
                job_id=job_id,
                frame_number=frame_number,
                timestamp_ms=timestamp_ms,
                swimmer_track_id=swimmer_track_id,
                crop_xyxy=[x1, y1, x2, y2],
                reason="empty_crop",
                duration_ms=(time.perf_counter() - started) * 1000.0,
            )

        try:
            from mmpose.apis import inference_topdown
        except Exception as exc:  # noqa: BLE001
            raise PoseEstimatorError(
                "MMPOSE_UNAVAILABLE",
                f"MMPose inference API unavailable: {exc}",
            ) from exc

        try:
            results = inference_topdown(
                self._model,
                image_bgr,
                bboxes=np.array([[x1, y1, x2, y2]], dtype=np.float32),
                bbox_format="xyxy",
            )
        except Exception as exc:  # noqa: BLE001
            return self._unusable(
                video_id=video_id,
                job_id=job_id,
                frame_number=frame_number,
                timestamp_ms=timestamp_ms,
                swimmer_track_id=swimmer_track_id,
                crop_xyxy=[x1, y1, x2, y2],
                reason="pose_inference_failure",
                duration_ms=(time.perf_counter() - started) * 1000.0,
                flags=[type(exc).__name__],
            )

        if not results:
            return self._unusable(
                video_id=video_id,
                job_id=job_id,
                frame_number=frame_number,
                timestamp_ms=timestamp_ms,
                swimmer_track_id=swimmer_track_id,
                crop_xyxy=[x1, y1, x2, y2],
                reason="pose_inference_failure",
                duration_ms=(time.perf_counter() - started) * 1000.0,
            )

        inst = results[0].pred_instances
        kpts = np.asarray(inst.keypoints[0])  # (133, 2) in original image coords
        scores = np.asarray(inst.keypoint_scores[0], dtype=np.float32)

        keypoints: list[Keypoint] = []
        for idx, name in enumerate(COCO_WHOLEBODY_KEYPOINT_NAMES):
            conf = float(scores[idx]) if idx < len(scores) else 0.0
            if conf < min_keypoint_confidence:
                # Do not invent missing landmarks.
                keypoints.append(
                    Keypoint(
                        name=name,
                        x=None,
                        y=None,
                        z=None,
                        confidence=conf,
                        x_crop=None,
                        y_crop=None,
                    )
                )
                continue
            ox = float(kpts[idx, 0])
            oy = float(kpts[idx, 1])
            keypoints.append(
                Keypoint(
                    name=name,
                    x=ox,
                    y=oy,
                    z=None,
                    confidence=conf,
                    x_crop=ox - x1,
                    y_crop=oy - y1,
                )
            )

        visible_core = sum(
            1
            for i in CORE_BODY_INDICES
            if i < len(keypoints) and keypoints[i].x is not None
        )
        overall = float(np.mean(scores)) if scores.size else 0.0
        duration_ms = (time.perf_counter() - started) * 1000.0
        flags: list[str] = []
        usable = True
        reason = None
        if visible_core < min_visible_core_joints:
            usable = False
            reason = "insufficient_visible_body_parts"
            flags.append("insufficient_visible_body_parts")
        if overall < min_keypoint_confidence:
            flags.append("low_confidence_pose")

        return PoseEstimate(
            video_id=video_id,
            job_id=job_id,
            frame_number=frame_number,
            timestamp_ms=timestamp_ms,
            swimmer_track_id=swimmer_track_id,
            crop_coordinates=[x1, y1, x2, y2],
            keypoints=keypoints,
            overall_pose_confidence=overall,
            model_name=self.model_name,
            model_version=self.model_version,
            inference_resolution=self._inference_input_size,
            processing_duration_ms=duration_ms,
            usable=usable,
            unusable_reason=reason,
            quality_flags=flags,
        )

    def _unusable(
        self,
        *,
        video_id: str,
        job_id: str,
        frame_number: int,
        timestamp_ms: float,
        swimmer_track_id: str | None,
        crop_xyxy: list[float],
        reason: str,
        duration_ms: float,
        flags: list[str] | None = None,
    ) -> PoseEstimate:
        empty = [
            Keypoint(name=n, x=None, y=None, z=None, confidence=0.0)
            for n in COCO_WHOLEBODY_KEYPOINT_NAMES
        ]
        return PoseEstimate(
            video_id=video_id,
            job_id=job_id,
            frame_number=frame_number,
            timestamp_ms=timestamp_ms,
            swimmer_track_id=swimmer_track_id,
            crop_coordinates=list(crop_xyxy),
            keypoints=empty,
            overall_pose_confidence=0.0,
            model_name=self.model_name,
            model_version=self.model_version,
            inference_resolution=self._inference_input_size,
            processing_duration_ms=duration_ms,
            usable=False,
            unusable_reason=reason,
            quality_flags=flags or [reason],
        )


def clear_model_cache() -> None:
    with _MODEL_LOCK:
        _MODEL_CACHE.clear()

"""Milestone 3 pose stages A/B/C — no automatic stage advancement."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

import cv2
import numpy as np

from app.config import Settings
from app.models.detector_adapter import DetectorAdapter
from app.models.rtmpose_adapter import RTMPoseWholeBodyAdapter
from app.services.pose_estimator import PoseEstimate, PoseEstimator, PoseEstimatorError
from app.services.pose_validation import run_pose_validation
from app.services.swimmer_detector import run_detection_and_tracking
from app.services.tracking_diagnostics import write_json
from app.utils.compat import assert_pose_stack_ready, collect_compat_report
from app.utils.logging import get_logger, log_stage
from app.utils.timestamps import frame_to_ms

logger = get_logger("video_analysis.pose")

PoseStage = Literal["A", "B", "C"]


class PoseStageError(Exception):
    def __init__(self, error_code: str, message: str) -> None:
        super().__init__(message)
        self.error_code = error_code
        self.message = message


@dataclass
class PoseStageResult:
    stage: PoseStage
    job_id: str
    video_id: str
    status: str
    poses: list[dict[str, Any]]
    unusable_frames: list[dict[str, Any]]
    artifact_paths: dict[str, str]
    model_versions: dict[str, str]
    dependency_versions: dict[str, Any]
    average_inference_ms: float
    acceptance_path: str | None
    limitations: list[str]


def acceptance_dir(settings: Settings) -> Path:
    path = settings.artifact_root / "pose_stage_acceptance"
    path.mkdir(parents=True, exist_ok=True)
    return path


def acceptance_path(settings: Settings, stage: PoseStage) -> Path:
    return acceptance_dir(settings) / f"stage_{stage}.json"


def require_prior_stage(settings: Settings, stage: PoseStage) -> None:
    """Hard gate: do not auto-advance. B needs A; C needs B."""
    if stage == "A":
        return
    needed = "A" if stage == "B" else "B"
    path = acceptance_path(settings, needed)  # type: ignore[arg-type]
    if not path.is_file():
        raise PoseStageError(
            "POSE_STAGE_GATE",
            f"Stage {stage} blocked: Stage {needed} acceptance missing at {path}. "
            "Run and pass the prior stage explicitly first.",
        )


def build_pose_estimator(settings: Settings) -> PoseEstimator:
    device = settings.pose_device
    if device == "auto":
        try:
            import torch

            device = "cuda:0" if torch.cuda.is_available() else "cpu"
        except Exception:  # noqa: BLE001
            device = "cpu"
    if device.startswith("cuda"):
        try:
            import torch

            if not torch.cuda.is_available():
                device = "cpu"
        except Exception:  # noqa: BLE001
            device = "cpu"

    config = Path(settings.pose_config_path)
    ckpt = Path(settings.pose_checkpoint_path)
    if not config.is_file():
        alt = Path(__file__).resolve().parents[2] / settings.pose_config_path
        config = alt if alt.is_file() else config
    if not ckpt.is_file():
        alt = Path(__file__).resolve().parents[2] / settings.pose_checkpoint_path
        ckpt = alt if alt.is_file() else ckpt

    estimator = RTMPoseWholeBodyAdapter(
        config_path=config,
        checkpoint_path=ckpt,
        device=device,
        inference_input_size=(settings.pose_input_width, settings.pose_input_height),
    )
    estimator.load()
    return estimator


def _expand_bbox(bbox: list[float], frame_w: int, frame_h: int, margin: float = 0.12) -> list[float]:
    x1, y1, x2, y2 = bbox
    bw, bh = x2 - x1, y2 - y1
    x1 -= bw * margin
    x2 += bw * margin
    y1 -= bh * margin
    y2 += bh * margin
    return [
        max(0.0, x1),
        max(0.0, y1),
        min(float(frame_w), x2),
        min(float(frame_h), y2),
    ]


def _track_observations(tracks_payload: dict[str, Any], target_id: str | None) -> list[dict[str, Any]]:
    tracks = tracks_payload.get("tracks") or []
    if target_id:
        for t in tracks:
            if t.get("track_id") == target_id:
                return list(t.get("observations") or [])
    # fallback: most hits
    if not tracks:
        return []
    best = max(tracks, key=lambda t: int(t.get("hits") or 0))
    return list(best.get("observations") or [])


def _run_tracking_for_pose(
    *,
    settings: Settings,
    job_id: str,
    video_id: str,
    video_path: Path,
    artifact_root: Path,
    detector: DetectorAdapter | None,
) -> dict[str, Any]:
    tracking = run_detection_and_tracking(
        settings=settings,
        job_id=job_id,
        video_id=video_id,
        video_path=video_path,
        artifact_root=artifact_root / "tracking_for_pose",
        options={"target_selection_mode": "automatic"},
        detector=detector,
    )
    tracks_path = tracking.artifact_paths.get("tracks_json")
    if not tracks_path or not Path(tracks_path).is_file():
        raise PoseStageError("TRACKS_MISSING", "Milestone 2 tracks.json was not produced")
    return json.loads(Path(tracks_path).read_text(encoding="utf-8"))


def run_pose_stage(
    *,
    settings: Settings,
    stage: PoseStage,
    job_id: str,
    video_id: str,
    source_path: Path,
    output_root: Path | None = None,
    detector: DetectorAdapter | None = None,
    pose_estimator: PoseEstimator | None = None,
    write_acceptance: bool = True,
) -> PoseStageResult:
    """
    Run exactly one pose stage.

    Stage A: one still image (or first frame of a video)
    Stage B: five-second clip
    Stage C: full clip

    Prior-stage acceptance files are required for B and C.
    """
    require_prior_stage(settings, stage)
    compat = assert_pose_stack_ready()
    estimator = pose_estimator or build_pose_estimator(settings)
    if not estimator.is_loaded():
        estimator.load()

    out_root = output_root or (settings.artifact_root / job_id / "pose" / f"stage_{stage}")
    out_root.mkdir(parents=True, exist_ok=True)

    log_stage(
        logger,
        stage=f"estimating_pose_{stage}",
        job_id=job_id,
        video_id=video_id,
        message=f"Starting pose Stage {stage}",
    )

    if stage == "A":
        framespecs = _stage_a_frames(source_path)
        media_path = source_path
    elif stage == "B":
        media_path = source_path
        framespecs = _stage_clip_frame_plan(
            source_path,
            max_duration_s=5.0,
            interval=max(1, settings.frame_processing_interval),
        )
    else:
        media_path = source_path
        framespecs = _stage_clip_frame_plan(
            source_path,
            max_duration_s=None,
            interval=max(1, settings.frame_processing_interval),
        )

    # Use M2 tracks/crops when source is a video; for a still image, detect once.
    tracks_payload: dict[str, Any] | None = None
    if _is_video(media_path):
        tracks_payload = _run_tracking_for_pose(
            settings=settings,
            job_id=job_id,
            video_id=video_id,
            video_path=media_path,
            artifact_root=out_root,
            detector=detector,
        )

    poses: list[PoseEstimate] = []
    unusable: list[dict[str, Any]] = []
    durations: list[float] = []

    if stage == "A" and not _is_video(media_path):
        image = cv2.imread(str(media_path))
        if image is None:
            raise PoseStageError("INVALID_IMAGE", f"Could not read image {media_path}")
        h, w = image.shape[:2]
        # Prefer detector box if available via injected detector; else use centered body prior.
        crop = _image_crop_from_detector_or_center(image, detector, settings)
        est = estimator.estimate_crop(
            image,
            crop_xyxy=crop,
            video_id=video_id,
            job_id=job_id,
            frame_number=0,
            timestamp_ms=0.0,
            swimmer_track_id="still-image",
            min_keypoint_confidence=settings.min_keypoint_confidence,
            min_visible_core_joints=settings.min_visible_core_joints,
        )
        poses.append(est)
        durations.append(est.processing_duration_ms)
        if not est.usable:
            unusable.append(
                {
                    "frame_number": 0,
                    "reason": est.unusable_reason,
                    "flags": est.quality_flags,
                }
            )
    else:
        cap = cv2.VideoCapture(str(media_path))
        if not cap.isOpened():
            raise PoseStageError("VIDEO_OPEN_FAILED", f"Could not open {media_path}")
        fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)

        obs_by_frame: dict[int, dict[str, Any]] = {}
        target_id = None
        if tracks_payload:
            target_id = (tracks_payload.get("target") or {}).get("track_id")
            for obs in _track_observations(tracks_payload, target_id):
                obs_by_frame[int(obs["frame_number"])] = obs

        for frame_number in framespecs:
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
            ok, frame = cap.read()
            if not ok or frame is None:
                unusable.append(
                    {
                        "frame_number": frame_number,
                        "reason": "detector_failure",
                        "flags": ["frame_read_failed"],
                    }
                )
                continue

            obs = obs_by_frame.get(frame_number)
            if obs is None:
                unusable.append(
                    {
                        "frame_number": frame_number,
                        "reason": "swimmer_outside_frame",
                        "flags": ["no_track_observation"],
                    }
                )
                # Explicit empty pose record with null landmarks
                empty = estimator.estimate_crop(
                    frame,
                    crop_xyxy=[0, 0, 1, 1],
                    video_id=video_id,
                    job_id=job_id,
                    frame_number=frame_number,
                    timestamp_ms=frame_to_ms(frame_number, fps),
                    swimmer_track_id=target_id,
                    min_keypoint_confidence=settings.min_keypoint_confidence,
                    min_visible_core_joints=settings.min_visible_core_joints,
                )
                # force reason
                empty.usable = False
                empty.unusable_reason = "swimmer_outside_frame"
                empty.quality_flags = ["no_track_observation"]
                poses.append(empty)
                durations.append(empty.processing_duration_ms)
                continue

            crop = _expand_bbox(list(map(float, obs["bbox"])), width, height)
            # Splash / occlusion flags from tracker
            track_flags = list(obs.get("flags") or [])
            est = estimator.estimate_crop(
                frame,
                crop_xyxy=crop,
                video_id=video_id,
                job_id=job_id,
                frame_number=frame_number,
                timestamp_ms=float(obs.get("timestamp_ms") or frame_to_ms(frame_number, fps)),
                swimmer_track_id=target_id,
                min_keypoint_confidence=settings.min_keypoint_confidence,
                min_visible_core_joints=settings.min_visible_core_joints,
            )
            if "temporary_occlusion" in track_flags:
                est.quality_flags.append("severe_occlusion")
                if not est.usable:
                    est.unusable_reason = est.unusable_reason or "severe_occlusion"
            if "track_switching_risk" in track_flags:
                est.quality_flags.append("track_switching_risk")
            poses.append(est)
            durations.append(est.processing_duration_ms)
            if not est.usable:
                unusable.append(
                    {
                        "frame_number": frame_number,
                        "reason": est.unusable_reason,
                        "flags": est.quality_flags,
                    }
                )

        cap.release()

    avg_ms = float(np.mean(durations)) if durations else 0.0
    usable_count = sum(1 for p in poses if p.usable)
    limitations: list[str] = []
    if usable_count == 0:
        raise PoseStageError(
            "POSE_STAGE_FAILED",
            f"Stage {stage} produced no usable pose frames",
        )
    if unusable:
        limitations.append(f"{len(unusable)} unusable frames recorded")

    raw_pose_dicts = [p.to_dict() for p in poses]
    pose_json_path = out_root / "raw_pose.json"
    unusable_path = out_root / "unusable_frames.json"
    summary_path = out_root / "pose_stage_summary.json"
    write_json(
        pose_json_path,
        {
            "stage": stage,
            "job_id": job_id,
            "video_id": video_id,
            "model_name": estimator.model_name,
            "model_version": estimator.model_version,
            "dependency_versions": compat,
            "dataset": "raw",
            "poses": raw_pose_dicts,
        },
    )
    write_json(unusable_path, {"unusable_frames": unusable})

    artifact_paths: dict[str, str] = {
        "raw_pose_json": str(pose_json_path.resolve()),
        "unusable_frames_json": str(unusable_path.resolve()),
        "pose_stage_summary": str(summary_path.resolve()),
    }

    # Milestone 4: validate/smooth from raw RTMPose output (raw file left unchanged).
    coverage_summary: dict[str, Any] = {}
    if settings.pose_smoothing_enabled:
        tracked_frames: set[int] | None = None
        if tracks_payload:
            tracked_frames = {
                int(obs["frame_number"])
                for obs in _track_observations(
                    tracks_payload,
                    (tracks_payload.get("target") or {}).get("track_id"),
                )
            }
        validation = run_pose_validation(
            settings=settings,
            job_id=job_id,
            video_id=video_id,
            raw_poses=raw_pose_dicts,
            output_root=out_root,
            video_path=media_path if _is_video(media_path) else None,
            tracked_frame_numbers=tracked_frames,
        )
        artifact_paths.update(validation.artifact_paths)
        limitations = list(dict.fromkeys([*limitations, *validation.limitations]))
        coverage_summary = validation.coverage

        # Verify raw artifact on disk was not rewritten by smoothing.
        disk_raw = json.loads(pose_json_path.read_text(encoding="utf-8"))
        if disk_raw.get("poses") != raw_pose_dicts:
            raise PoseStageError(
                "RAW_POSE_MUTATED",
                "raw_pose.json was altered after Milestone 3 write",
            )

    write_json(
        summary_path,
        {
            "stage": stage,
            "usable_frames": usable_count,
            "total_pose_records": len(poses),
            "unusable_frames": len(unusable),
            "average_inference_ms": avg_ms,
            "device_mode": compat.get("device_mode"),
            "torch_cuda_available": compat.get("torch_cuda_available"),
            "pose_coverage": coverage_summary,
            "milestone": "4" if settings.pose_smoothing_enabled else "3",
        },
    )

    accept_path = None
    status = "completed_with_limitations" if limitations else "completed"
    if write_acceptance:
        accept_path = str(acceptance_path(settings, stage).resolve())
        write_json(
            acceptance_path(settings, stage),
            {
                "stage": stage,
                "status": "accepted",
                "job_id": job_id,
                "video_id": video_id,
                "usable_frames": usable_count,
                "average_inference_ms": avg_ms,
                "pose_json": str(pose_json_path.resolve()),
                "model_version": estimator.model_version,
                "pose_coverage": coverage_summary,
            },
        )

    return PoseStageResult(
        stage=stage,
        job_id=job_id,
        video_id=video_id,
        status=status,
        poses=raw_pose_dicts,
        unusable_frames=unusable,
        artifact_paths=artifact_paths,
        model_versions={
            "pose": estimator.model_name,
            "pose_version": estimator.model_version,
            "engine": settings.engine_version,
            "milestone": "4" if settings.pose_smoothing_enabled else "3",
            "stage": stage,
        },
        dependency_versions=compat,
        average_inference_ms=avg_ms,
        acceptance_path=accept_path,
        limitations=limitations,
    )


def _is_video(path: Path) -> bool:
    return path.suffix.lower() in {".mp4", ".mov", ".avi", ".mkv", ".webm"}


def _stage_a_frames(path: Path) -> list[int]:
    return [0]


def _stage_clip_frame_plan(
    path: Path,
    max_duration_s: float | None,
    interval: int = 1,
) -> list[int]:
    cap = cv2.VideoCapture(str(path))
    if not cap.isOpened():
        raise PoseStageError("VIDEO_OPEN_FAILED", f"Could not open {path}")
    fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    cap.release()
    if total <= 0:
        raise PoseStageError("EMPTY_VIDEO", f"No frames in {path}")
    if max_duration_s is None:
        end = total
    else:
        end = min(total, int(max_duration_s * fps))
    return list(range(0, max(1, end), max(1, interval)))


def _image_crop_from_detector_or_center(
    image_bgr: np.ndarray,
    detector: DetectorAdapter | None,
    settings: Settings,
) -> list[float]:
    h, w = image_bgr.shape[:2]
    if detector is not None:
        dets = detector.detect(
            image_bgr,
            frame_number=0,
            timestamp_ms=0.0,
            min_confidence=settings.min_detection_confidence,
        )
        if dets:
            frame_area = float(max(1, w * h))
            # Prefer plausible person boxes: confidence × normalized area.
            # Do not blindly take max confidence (tiny false positives) or max area alone.
            def _score(d):  # noqa: ANN001
                area_ratio = d.bbox.area / frame_area
                if area_ratio < 0.01:
                    return -1.0
                return float(d.confidence) * min(1.0, area_ratio * 8.0)

            ranked = sorted(dets, key=_score, reverse=True)
            if _score(ranked[0]) > 0:
                return _expand_bbox(ranked[0].bbox.as_list(), w, h)
    # Center prior — not inventing pose, only a crop window for still-image stage.
    return [w * 0.2, h * 0.1, w * 0.8, h * 0.95]


def health_pose_model(settings: Settings) -> dict[str, Any]:
    report = collect_compat_report()
    config = Path(settings.pose_config_path)
    ckpt = Path(settings.pose_checkpoint_path)
    service_root = Path(__file__).resolve().parents[2]
    if not config.is_file():
        config = service_root / settings.pose_config_path
    if not ckpt.is_file():
        ckpt = service_root / settings.pose_checkpoint_path
    report["pose_config_present"] = config.is_file()
    report["pose_checkpoint_present"] = ckpt.is_file()
    report["pose_config_path"] = str(config)
    report["pose_checkpoint_path"] = str(ckpt)
    try:
        est = build_pose_estimator(settings)
        report["pose_model_loaded"] = est.is_loaded()
        report["pose_model_name"] = est.model_name
        report["pose_model_version"] = est.model_version
    except Exception as exc:  # noqa: BLE001
        report["pose_model_loaded"] = False
        report["pose_model_error"] = str(exc)
    return report

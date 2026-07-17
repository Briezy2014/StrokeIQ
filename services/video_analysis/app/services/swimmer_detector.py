"""Frame-loop detection + tracking orchestration (Milestone 2)."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import cv2

from app.config import Settings
from app.models.detector_adapter import Detection, DetectorAdapter
from app.models.rtmdet_adapter import RTMDetOnnxAdapter
from app.services.swimmer_tracker import SwimmerTracker
from app.services.target_selector import select_target
from app.services.tracking_diagnostics import (
    build_tracking_quality_summary,
    compute_target_coverage,
    save_target_frames,
    write_annotated_tracking_video,
    write_json,
)
from app.utils.logging import get_logger, log_stage
from app.utils.timestamps import frame_to_ms

logger = get_logger("video_analysis.detection")


class DetectionError(Exception):
    def __init__(self, error_code: str, message: str, *, retriable: bool = False) -> None:
        super().__init__(message)
        self.error_code = error_code
        self.message = message
        self.retriable = retriable


@dataclass
class DetectionTrackingResult:
    detections: list[dict[str, Any]]
    tracks: list[dict[str, Any]]
    events: list[dict[str, Any]]
    target: dict[str, Any]
    quality_summary: dict[str, Any]
    artifact_paths: dict[str, str | list[str] | None]
    model_versions: dict[str, str]
    config_versions: dict[str, Any]
    limitations: list[str]
    lost_extended: bool
    completed_with_limitations: bool


def build_detector(settings: Settings, override: DetectorAdapter | None = None) -> DetectorAdapter:
    if override is not None:
        return override
    backend = settings.detector_backend.lower()
    if backend == "scripted":
        raise DetectionError(
            "DETECTOR_NOT_CONFIGURED",
            "scripted detector must be injected for tests",
            retriable=False,
        )
    if backend in {"rtmdet", "rtmdet_onnx", "auto"}:
        path = Path(settings.detector_model_path)
        if not path.is_file():
            # Resolve relative to service root
            alt = Path(__file__).resolve().parents[2] / settings.detector_model_path
            path = alt if alt.is_file() else path
        if not path.is_file():
            raise DetectionError(
                "DETECTOR_MODEL_MISSING",
                f"RTMDet model missing at {settings.detector_model_path}. "
                "Run scripts/download_rtmdet.py",
                retriable=False,
            )
        return RTMDetOnnxAdapter(
            path,
            input_size=settings.inference_resolution,
        )
    raise DetectionError(
        "UNSUPPORTED_DETECTOR",
        f"Unsupported detector_backend={settings.detector_backend}",
        retriable=False,
    )


def run_detection_and_tracking(
    *,
    settings: Settings,
    job_id: str,
    video_id: str,
    video_path: Path,
    artifact_root: Path,
    options: dict[str, Any] | None = None,
    detector: DetectorAdapter | None = None,
) -> DetectionTrackingResult:
    options = options or {}
    det = build_detector(settings, override=detector)
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise DetectionError(
            "VIDEO_OPEN_FAILED",
            f"Could not open video for detection: {video_path}",
            retriable=True,
        )

    fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    interval = max(1, int(settings.frame_processing_interval))

    tracker = SwimmerTracker(
        max_lost_frames=settings.max_lost_frames,
        max_active_tracks=settings.max_active_tracks,
        frame_width=width or 1,
        frame_height=height or 1,
    )

    all_detections: list[Detection] = []
    processed_frames = 0
    frames_with_detections = 0
    consecutive_target_misses = 0
    lost_extended = False
    had_target = False
    selected_track_id: str | None = options.get("target_track_id")

    log_stage(
        logger,
        stage="detecting_swimmer",
        job_id=job_id,
        video_id=video_id,
        message="Starting detection/tracking loop",
        detector=det.model_name,
        interval=interval,
    )

    frame_idx = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if frame_idx % interval != 0:
            frame_idx += 1
            continue

        # Optional inference resize for speed; keep coords in original space via scale.
        infer_frame = frame
        scale_x = scale_y = 1.0
        if settings.inference_resolution and max(height, width) > 0:
            # RTMDet adapter letterboxes internally; no extra resize required here.
            infer_frame = frame

        timestamp_ms = frame_to_ms(frame_idx, fps)
        detections = det.detect(
            infer_frame,
            frame_number=frame_idx,
            timestamp_ms=timestamp_ms,
            min_confidence=settings.min_detection_confidence,
        )
        if scale_x != 1.0 or scale_y != 1.0:
            for d in detections:
                d.bbox.x1 *= scale_x
                d.bbox.x2 *= scale_x
                d.bbox.y1 *= scale_y
                d.bbox.y2 *= scale_y

        all_detections.extend(detections)
        processed_frames += 1
        if detections:
            frames_with_detections += 1
        tracker.update(detections, frame_bgr=frame)

        # Provisional automatic target for lost-target monitoring
        provisional = select_target(
            tracker.tracks,
            mode="track_id" if selected_track_id else "automatic",
            track_id=selected_track_id,
            frame_width=width,
            frame_height=height,
            min_confidence=settings.tracking_confidence_threshold,
        )
        if provisional.track_id:
            had_target = True
            selected_track_id = selected_track_id or provisional.track_id
            track = next(t for t in tracker.tracks if t.track_id == provisional.track_id)
            if track.last and track.last.frame_number == frame_idx:
                consecutive_target_misses = 0
            else:
                consecutive_target_misses += 1
        elif had_target:
            consecutive_target_misses += 1

        if had_target and consecutive_target_misses > settings.max_target_lost_frames:
            lost_extended = True
            cap.release()
            raise DetectionError(
                "TARGET_LOST_EXTENDED",
                "Target swimmer lost for an extended period; refusing silent continuation",
                retriable=False,
            )

        frame_idx += 1

    cap.release()

    mode = str(options.get("target_selection_mode") or "automatic")
    norm = options.get("target_normalized_xy")
    norm_xy = None
    if isinstance(norm, dict) and "x" in norm and "y" in norm:
        norm_xy = (float(norm["x"]), float(norm["y"]))
    elif isinstance(norm, (list, tuple)) and len(norm) == 2:
        norm_xy = (float(norm[0]), float(norm[1]))

    target = select_target(
        tracker.tracks,
        mode=mode if mode in {"automatic", "track_id", "normalized_coordinate", "bounding_box"} else "automatic",  # type: ignore[arg-type]
        track_id=options.get("target_track_id"),
        normalized_xy=norm_xy,
        bbox=options.get("target_bbox"),
        frame_width=width,
        frame_height=height,
        min_confidence=settings.tracking_confidence_threshold,
    )

    target_track = next((t for t in tracker.tracks if t.track_id == target.track_id), None)
    coverage = compute_target_coverage(target_track, processed_frames)

    limitations: list[str] = []
    completed_with_limitations = False
    if target.uncertain:
        limitations.append(f"Target selection uncertain: {target.reason}")
        completed_with_limitations = True
    if coverage < 0.85:
        limitations.append(
            f"Target track coverage only {coverage:.0%} of processed frames"
        )
        completed_with_limitations = True
    if frames_with_detections == 0:
        raise DetectionError(
            "NO_DETECTIONS",
            "Detector returned no person/swimmer detections for the video",
            retriable=False,
        )
    if any(e.get("type") == "lost_track" for e in tracker.events):
        limitations.append("One or more tracks were lost during the clip")
        completed_with_limitations = True

    # Artifacts
    det_path = artifact_root / "detections.json"
    tracks_path = artifact_root / "tracks.json"
    summary_path = artifact_root / "tracking_quality_summary.json"
    events_path = artifact_root / "events" / "tracking_events.json"
    annotated_path = artifact_root / "annotated_tracking.mp4"
    target_frames_dir = artifact_root / "frames" / "target"

    quality = build_tracking_quality_summary(
        tracks=tracker.tracks,
        target=target,
        processed_frames=processed_frames,
        frames_with_detections=frames_with_detections,
        events=tracker.events,
        target_coverage=coverage,
        lost_extended=lost_extended,
    )

    detections_payload = {
        "job_id": job_id,
        "video_id": video_id,
        "model_name": det.model_name,
        "model_version": det.model_version,
        "config": _config_snapshot(settings),
        "detections": [d.to_dict() for d in all_detections],
    }
    tracks_payload = {
        "job_id": job_id,
        "video_id": video_id,
        "model_name": det.model_name,
        "model_version": det.model_version,
        "config": _config_snapshot(settings),
        "target": target.to_dict(),
        "tracks": [t.to_dict() for t in tracker.tracks],
        "events": tracker.events,
    }

    write_json(det_path, detections_payload)
    write_json(tracks_path, tracks_payload)
    write_json(summary_path, {**quality, "model_versions": {
        "detector": det.model_name,
        "detector_version": det.model_version,
        "engine": settings.engine_version,
    }, "config": _config_snapshot(settings)})
    write_json(events_path, {"events": tracker.events})

    annotated = write_annotated_tracking_video(
        video_path=video_path,
        out_path=annotated_path,
        tracks=tracker.tracks,
        target_track_id=target.track_id,
        frame_interval=interval,
        fps=fps,
    )
    target_frame_paths = save_target_frames(
        video_path=video_path,
        out_dir=target_frames_dir,
        target_track=target_track,
    )

    if annotated is None:
        limitations.append("Annotated tracking video could not be written")
        completed_with_limitations = True

    return DetectionTrackingResult(
        detections=detections_payload["detections"],
        tracks=tracks_payload["tracks"],
        events=tracker.events,
        target=target.to_dict(),
        quality_summary=quality,
        artifact_paths={
            "detections_json": str(det_path.resolve()),
            "tracks_json": str(tracks_path.resolve()),
            "tracking_quality_summary": str(summary_path.resolve()),
            "tracking_events_json": str(events_path.resolve()),
            "annotated_tracking_video": annotated,
            "selected_target_frames": target_frame_paths,
        },
        model_versions={
            "detector": det.model_name,
            "detector_version": det.model_version,
            "engine": settings.engine_version,
            "milestone": "2",
        },
        config_versions=_config_snapshot(settings),
        limitations=limitations,
        lost_extended=lost_extended,
        completed_with_limitations=completed_with_limitations,
    )


def _config_snapshot(settings: Settings) -> dict[str, Any]:
    return {
        "min_detection_confidence": settings.min_detection_confidence,
        "tracking_confidence_threshold": settings.tracking_confidence_threshold,
        "max_lost_frames": settings.max_lost_frames,
        "max_target_lost_frames": settings.max_target_lost_frames,
        "frame_processing_interval": settings.frame_processing_interval,
        "inference_resolution": settings.inference_resolution,
        "max_active_tracks": settings.max_active_tracks,
        "detector_backend": settings.detector_backend,
        "detector_model_path": str(settings.detector_model_path),
        "engine_version": settings.engine_version,
    }

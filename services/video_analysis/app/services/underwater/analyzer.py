"""UnderwaterAnalyzer — Milestone 6 entry point."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from app.config import Settings
from app.services.underwater.artifacts import write_underwater_artifacts
from app.services.underwater.detector import UnderwaterDetectorParams, detect_underwater_phase
from app.services.underwater.metrics_calculator import compute_underwater_metrics
from app.services.underwater.signals import extract_underwater_signals
from app.services.underwater.types import MetricValue
from app.utils.logging import get_logger

logger = get_logger("video_analysis.underwater")


@dataclass
class UnderwaterAnalysisResult:
    job_id: str
    video_id: str
    view_hint: str
    phase: dict[str, Any] | None
    events: list[dict[str, Any]]
    metrics: list[dict[str, Any]]
    kick_frames: list[int]
    breakout_frame: int | None
    first_surface_stroke_frame: int | None
    artifact_paths: dict[str, str]
    detection_method: str
    quality_flags: list[str]
    limitations: list[str] = field(default_factory=list)
    summary: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "job_id": self.job_id,
            "video_id": self.video_id,
            "view_hint": self.view_hint,
            "phase": self.phase,
            "events": self.events,
            "metrics": self.metrics,
            "kick_frames": self.kick_frames,
            "breakout_frame": self.breakout_frame,
            "first_surface_stroke_frame": self.first_surface_stroke_frame,
            "artifact_paths": self.artifact_paths,
            "detection_method": self.detection_method,
            "quality_flags": self.quality_flags,
            "limitations": self.limitations,
            "summary": self.summary,
        }


class UnderwaterAnalyzer:
    """Underwater-phase, dolphin-kick, and breakout analysis (no Gemini)."""

    def __init__(
        self,
        *,
        settings: Settings | None = None,
        params: UnderwaterDetectorParams | None = None,
    ) -> None:
        self.settings = settings
        self.params = params or UnderwaterDetectorParams(
            min_kick_interval_s=getattr(settings, "underwater_min_kick_interval_s", 0.28)
            if settings
            else 0.28,
            max_kick_interval_s=getattr(settings, "underwater_max_kick_interval_s", 1.10)
            if settings
            else 1.10,
            kick_prominence_px=getattr(settings, "underwater_kick_prominence_px", 4.0)
            if settings
            else 4.0,
            min_underwater_duration_s=getattr(settings, "underwater_min_duration_s", 0.40)
            if settings
            else 0.40,
        )

    def analyze(
        self,
        smoothed_poses: list[dict[str, Any]],
        *,
        job_id: str,
        video_id: str,
        output_dir: Path,
        view_hint: str = "side",
        pool_distance_calibrated: bool = False,
        surface_stroke_entry_frames: list[int] | None = None,
        track_observations: list[dict[str, Any]] | None = None,
        frame_splash_scores: dict[int, float] | None = None,
    ) -> UnderwaterAnalysisResult:
        limitations: list[str] = []
        signals = extract_underwater_signals(
            smoothed_poses,
            track_observations=track_observations,
            frame_splash_scores=frame_splash_scores,
        )
        detection = detect_underwater_phase(
            signals,
            params=self.params,
            view_hint=view_hint,
            surface_stroke_entry_frames=surface_stroke_entry_frames,
        )
        metrics = compute_underwater_metrics(
            signals=signals,
            detection=detection,
            pool_distance_calibrated=pool_distance_calibrated,
        )
        artifact_paths = write_underwater_artifacts(
            output_dir,
            job_id=job_id,
            video_id=video_id,
            signals=signals,
            detection=detection,
            metrics=metrics,
            events=detection.events,
        )

        if detection.phase is None:
            limitations.append("no_valid_underwater_phase")
        if "feet_obscured" in detection.quality_flags:
            limitations.append("feet_obscured")
        if "short_clip" in detection.quality_flags:
            limitations.append("short_clip")

        summary = {
            "underwater_duration_s": _mval(metrics, "underwater_duration"),
            "kick_count": _mval(metrics, "estimated_underwater_kick_count"),
            "breakout_timestamp_ms": _mval(metrics, "breakout_timestamp"),
            "breakout_frame": detection.breakout_frame,
            "first_surface_stroke_frame": detection.first_surface_stroke_frame,
            "breakout_confidence": _mval(metrics, "breakout_confidence"),
            "quality_score": _mval(metrics, "underwater_analysis_quality_score"),
        }

        result = UnderwaterAnalysisResult(
            job_id=job_id,
            video_id=video_id,
            view_hint=view_hint,
            phase=detection.phase.to_dict() if detection.phase else None,
            events=[e.to_dict() for e in detection.events],
            metrics=[m.to_dict() for m in metrics],
            kick_frames=detection.kick_frames,
            breakout_frame=detection.breakout_frame,
            first_surface_stroke_frame=detection.first_surface_stroke_frame,
            artifact_paths=artifact_paths,
            detection_method=detection.method,
            quality_flags=detection.quality_flags,
            limitations=limitations,
            summary=summary,
        )
        summary_path = output_dir / "underwater_analysis_summary.json"
        summary_path.write_text(json.dumps(result.to_dict(), indent=2), encoding="utf-8")
        artifact_paths["underwater_analysis_summary"] = str(summary_path.resolve())
        result.artifact_paths = artifact_paths

        logger.info(
            "Underwater analysis complete job=%s kicks=%s breakout=%s",
            job_id,
            summary.get("kick_count"),
            summary.get("breakout_frame"),
        )
        return result

    def analyze_from_smoothed_json(
        self,
        smoothed_pose_path: Path,
        *,
        job_id: str,
        video_id: str,
        output_dir: Path,
        view_hint: str = "side",
        pool_distance_calibrated: bool = False,
        surface_stroke_entry_frames: list[int] | None = None,
        track_observations: list[dict[str, Any]] | None = None,
    ) -> UnderwaterAnalysisResult:
        payload = json.loads(smoothed_pose_path.read_text(encoding="utf-8"))
        poses = payload.get("poses") or payload
        if not isinstance(poses, list):
            raise ValueError("smoothed pose JSON must contain a poses list")
        return self.analyze(
            poses,
            job_id=job_id,
            video_id=video_id,
            output_dir=output_dir,
            view_hint=view_hint,
            pool_distance_calibrated=pool_distance_calibrated,
            surface_stroke_entry_frames=surface_stroke_entry_frames,
            track_observations=track_observations,
        )


def _mval(metrics: list[MetricValue], name: str) -> float | int | None:
    for m in metrics:
        if m.name == name:
            return m.value
    return None

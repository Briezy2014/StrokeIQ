"""ButterflyAnalyzer — Milestone 5 surface-stroke analysis entry point."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from app.config import Settings
from app.services.butterfly.artifacts import write_butterfly_artifacts
from app.services.butterfly.cycle_detector import CycleDetectorParams, detect_butterfly_cycles
from app.services.butterfly.metrics_calculator import compute_butterfly_metrics
from app.services.butterfly.signals import extract_butterfly_signals
from app.services.butterfly.types import MetricValue, StrokeEvent
from app.utils.logging import get_logger

logger = get_logger("video_analysis.butterfly")


@dataclass
class ButterflyAnalysisResult:
    job_id: str
    video_id: str
    stroke_hint: str
    view_hint: str
    cycles: list[dict[str, Any]]
    events: list[dict[str, Any]]
    metrics: list[dict[str, Any]]
    entry_frames: list[int]
    breath_frames: list[int]
    artifact_paths: dict[str, str]
    detection_method: str
    quality_flags: list[str]
    limitations: list[str] = field(default_factory=list)
    summary: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "job_id": self.job_id,
            "video_id": self.video_id,
            "stroke_hint": self.stroke_hint,
            "view_hint": self.view_hint,
            "cycles": self.cycles,
            "events": self.events,
            "metrics": self.metrics,
            "entry_frames": self.entry_frames,
            "breath_frames": self.breath_frames,
            "artifact_paths": self.artifact_paths,
            "detection_method": self.detection_method,
            "quality_flags": self.quality_flags,
            "limitations": self.limitations,
            "summary": self.summary,
        }


class ButterflyAnalyzer:
    """Modular butterfly surface-stroke analyzer using Milestone 4 smoothed poses."""

    def __init__(
        self,
        *,
        settings: Settings | None = None,
        detector_params: CycleDetectorParams | None = None,
    ) -> None:
        self.settings = settings
        self.detector_params = detector_params or CycleDetectorParams(
            min_cycle_duration_s=getattr(settings, "butterfly_min_cycle_duration_s", 0.70)
            if settings
            else 0.70,
            max_cycle_duration_s=getattr(settings, "butterfly_max_cycle_duration_s", 2.20)
            if settings
            else 2.20,
            min_peak_prominence=getattr(settings, "butterfly_min_peak_prominence", 0.08)
            if settings
            else 0.08,
            min_bilateral_sync=getattr(settings, "butterfly_min_bilateral_sync", 0.25)
            if settings
            else 0.25,
        )

    def analyze(
        self,
        smoothed_poses: list[dict[str, Any]],
        *,
        job_id: str,
        video_id: str,
        output_dir: Path,
        stroke_hint: str = "butterfly",
        view_hint: str = "side",
        pool_distance_calibrated: bool = False,
    ) -> ButterflyAnalysisResult:
        limitations: list[str] = []
        if not smoothed_poses:
            limitations.append("no_smoothed_poses")

        signals = extract_butterfly_signals(smoothed_poses)
        detection = detect_butterfly_cycles(
            signals,
            params=self.detector_params,
            view_hint=view_hint,
        )
        metrics = compute_butterfly_metrics(
            signals=signals,
            detection=detection,
            stroke_hint=stroke_hint,
            pool_distance_calibrated=pool_distance_calibrated,
        )
        events: list[StrokeEvent] = detection.events
        artifact_paths = write_butterfly_artifacts(
            output_dir,
            job_id=job_id,
            video_id=video_id,
            signals=signals,
            detection=detection,
            metrics=metrics,
            events=events,
        )

        if "fewer_than_two_complete_cycles" in detection.quality_flags:
            limitations.append("fewer_than_two_complete_cycles")
        if detection.view_suitability < 0.5:
            limitations.append("view_suitability_low_for_surface_butterfly")

        summary = {
            "complete_cycles": sum(1 for c in detection.cycles if c.complete),
            "stroke_count": _metric_value(metrics, "stroke_count"),
            "average_stroke_rate": _metric_value(metrics, "average_stroke_rate"),
            "breathing_event_estimate": _metric_value(metrics, "breathing_event_estimate"),
            "timing_variability": _metric_value(metrics, "cycle_to_cycle_timing_variability"),
        }

        report_path = output_dir / "butterfly_analysis_summary.json"
        result = ButterflyAnalysisResult(
            job_id=job_id,
            video_id=video_id,
            stroke_hint=stroke_hint,
            view_hint=view_hint,
            cycles=[c.to_dict() for c in detection.cycles],
            events=[e.to_dict() for e in events],
            metrics=[m.to_dict() for m in metrics],
            entry_frames=detection.entry_frames,
            breath_frames=detection.breath_frames,
            artifact_paths=artifact_paths,
            detection_method=detection.method,
            quality_flags=detection.quality_flags,
            limitations=limitations,
            summary=summary,
        )
        report_path.write_text(json.dumps(result.to_dict(), indent=2), encoding="utf-8")
        artifact_paths["butterfly_analysis_summary"] = str(report_path.resolve())
        result.artifact_paths = artifact_paths

        logger.info(
            "Butterfly analysis complete job=%s cycles=%s rate=%s",
            job_id,
            summary.get("complete_cycles"),
            summary.get("average_stroke_rate"),
        )
        return result

    def analyze_from_smoothed_json(
        self,
        smoothed_pose_path: Path,
        *,
        job_id: str,
        video_id: str,
        output_dir: Path,
        stroke_hint: str = "butterfly",
        view_hint: str = "side",
        pool_distance_calibrated: bool = False,
    ) -> ButterflyAnalysisResult:
        payload = json.loads(smoothed_pose_path.read_text(encoding="utf-8"))
        poses = payload.get("poses") or payload
        if not isinstance(poses, list):
            raise ValueError("smoothed pose JSON must contain a poses list")
        return self.analyze(
            poses,
            job_id=job_id,
            video_id=video_id,
            output_dir=output_dir,
            stroke_hint=stroke_hint,
            view_hint=view_hint,
            pool_distance_calibrated=pool_distance_calibrated,
        )


def _metric_value(metrics: list[MetricValue], name: str) -> float | int | None:
    for m in metrics:
        if m.name == name:
            return m.value
    return None

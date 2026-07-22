"""FinishAnalyzer — finish-event framework (Milestone 7)."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np

from app.config import Settings
from app.services.butterfly.signals import _kp_xy
from app.services.turn_finish.artifacts import write_turn_artifacts
from app.services.turn_finish.types import MetricValue, RaceEvent, WallCalibration, confidence_label
from app.services.turn_finish.wall_calibration import calibrate_wall
from app.services.turn_finish.turn_analyzer import _extract_series, _view_supports_turns
from app.utils.logging import get_logger

logger = get_logger("video_analysis.finish")


@dataclass
class FinishAnalysisResult:
    job_id: str
    video_id: str
    calibration: dict[str, Any]
    events: list[dict[str, Any]]
    metrics: list[dict[str, Any]]
    artifact_paths: dict[str, str]
    quality_flags: list[str]
    limitations: list[str] = field(default_factory=list)
    summary: dict[str, Any] = field(default_factory=dict)
    view_supported: bool = True

    def to_dict(self) -> dict[str, Any]:
        return {
            "job_id": self.job_id,
            "video_id": self.video_id,
            "calibration": self.calibration,
            "events": self.events,
            "metrics": self.metrics,
            "artifact_paths": self.artifact_paths,
            "quality_flags": self.quality_flags,
            "limitations": self.limitations,
            "summary": self.summary,
            "view_supported": self.view_supported,
        }


class FinishAnalyzer:
    """Detect finish events when the wall/finish is reliably visible."""

    def __init__(self, *, settings: Settings | None = None) -> None:
        self.settings = settings

    def analyze(
        self,
        smoothed_poses: list[dict[str, Any]],
        *,
        job_id: str,
        video_id: str,
        output_dir: Path,
        view_hint: str = "side",
        stroke_hint: str = "butterfly",
        manual_wall_line: dict[str, Any] | None = None,
        pool_geometry: dict[str, Any] | None = None,
        lane_line_termination_x: float | None = None,
        starting_block_x: float | None = None,
        surface_stroke_entry_frames: list[int] | None = None,
        frame_width: int | None = None,
        image_bgr: Any | None = None,
        blocked_by_obstacle: bool = False,
        clip_ends_before_contact: bool = False,
    ) -> FinishAnalysisResult:
        output_dir.mkdir(parents=True, exist_ok=True)
        limitations: list[str] = []
        flags: list[str] = []

        calibration = calibrate_wall(
            smoothed_poses=smoothed_poses,
            frame_width=frame_width,
            manual_wall_line=manual_wall_line,
            pool_geometry=pool_geometry,
            lane_line_termination_x=lane_line_termination_x,
            starting_block_x=starting_block_x,
            image_bgr=image_bgr,
        )
        view_supported = _view_supports_turns(view_hint, calibration)
        if not view_supported:
            limitations.append("view_does_not_support_reliable_finish_analysis")
        if blocked_by_obstacle:
            flags.append("swimmer_blocked_by_official_or_lane_rope")
        if clip_ends_before_contact:
            flags.append("clip_ending_before_wall_contact")

        series = _extract_series(smoothed_poses, calibration)
        events = _detect_finish_events(
            series=series,
            calibration=calibration,
            view_supported=view_supported,
            stroke_hint=stroke_hint,
            surface_stroke_entry_frames=surface_stroke_entry_frames or [],
            blocked=blocked_by_obstacle,
            clip_ends_before_contact=clip_ends_before_contact,
        )
        metrics = _compute_finish_metrics(events, calibration, view_supported)

        artifacts = write_turn_artifacts(
            output_dir,
            job_id=job_id,
            video_id=video_id,
            kind="finish",
            calibration=calibration,
            events=events,
            metrics=metrics,
            series=series,
            image_bgr=image_bgr,
        )

        summary = {
            "view_supported": view_supported,
            "wall_in_frame": calibration.wall_in_frame,
            "calibration_method": calibration.method,
            "finish_contact_frame": _frame(events, "wall_contact"),
            "final_stroke_frame": _frame(events, "final_complete_stroke_cycle"),
            "finish_timing_confidence": _metric_val(metrics, "finish_timing_confidence"),
        }

        result = FinishAnalysisResult(
            job_id=job_id,
            video_id=video_id,
            calibration=calibration.to_dict(),
            events=[e.to_dict() for e in events],
            metrics=[m.to_dict() for m in metrics],
            artifact_paths=artifacts,
            quality_flags=sorted(set(flags + calibration.quality_flags)),
            limitations=list(dict.fromkeys([*limitations, *calibration.limitations])),
            summary=summary,
            view_supported=view_supported,
        )
        summary_path = output_dir / "finish_analysis_summary.json"
        summary_path.write_text(json.dumps(result.to_dict(), indent=2), encoding="utf-8")
        artifacts["finish_analysis_summary"] = str(summary_path.resolve())
        result.artifact_paths = artifacts
        logger.info(
            "Finish analysis complete job=%s contact=%s",
            job_id,
            summary.get("finish_contact_frame"),
        )
        return result


def _detect_finish_events(
    *,
    series: dict[str, Any],
    calibration: WallCalibration,
    view_supported: bool,
    stroke_hint: str,
    surface_stroke_entry_frames: list[int],
    blocked: bool,
    clip_ends_before_contact: bool,
) -> list[RaceEvent]:
    names = [
        "final_complete_stroke_cycle",
        "final_hand_entry",
        "final_reach",
        "glide_into_wall",
        "wall_contact",
        "shortened_or_added_stroke_estimate",
        "head_position_observation",
    ]
    if not view_supported:
        return [
            RaceEvent.unavailable(
                event_type=n,
                method="finish_framework_view_gate",
                reason="view_or_calibration_does_not_support_reliable_finish_analysis",
            )
            for n in names
        ]

    frames = series["frames"]
    ts = series["timestamps_ms"]
    dist = series["dist_to_wall"]
    wrist_x = series["wrist_x"]
    n = len(frames)
    events: list[RaceEvent] = []

    # Prefer surface entries at/before a near-wall contact when contact is visible.
    # If the swimmer never reaches the wall, keep all provided surface entries.
    contact_i = int(np.nanargmin(dist)) if np.any(np.isfinite(dist)) else None
    near_thr = max(40.0, 0.08 * float(calibration.frame_width or 640))
    contact_usable = (
        contact_i is not None
        and calibration.wall_in_frame
        and np.isfinite(dist[contact_i])
        and float(dist[contact_i]) <= near_thr
        and not blocked
        and not clip_ends_before_contact
    )
    contact_frame = int(frames[contact_i]) if contact_usable else None
    pre_entries = [
        fr for fr in surface_stroke_entry_frames if contact_frame is None or fr <= contact_frame
    ]

    # Final complete stroke cycle from surface entries (last full cycle before wall)
    final_cycle_start = None
    final_hand_entry = None
    if len(pre_entries) >= 2:
        final_cycle_start = pre_entries[-2]
        final_hand_entry = pre_entries[-1]
    elif len(pre_entries) == 1:
        final_hand_entry = pre_entries[-1]
        events.append(
            RaceEvent.unavailable(
                event_type="final_complete_stroke_cycle",
                method="last_complete_cycle_from_m5_entries",
                reason="fewer_than_two_surface_entries_for_complete_cycle",
            )
        )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="final_complete_stroke_cycle",
                method="last_complete_cycle_from_m5_entries",
                reason="no_surface_stroke_entries",
            )
        )

    if final_cycle_start is not None:
        idx = _idx(frames, final_cycle_start)
        events.append(
            _ev("final_complete_stroke_cycle", series, idx, "last_complete_cycle_from_m5_entries", ["left_wrist", "right_wrist"], 0.8)
        )

    if final_hand_entry is not None:
        idx = _idx(frames, final_hand_entry)
        events.append(_ev("final_hand_entry", series, idx, "last_hand_entry_before_wall", ["left_wrist", "right_wrist"], 0.75))
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="final_hand_entry",
                method="last_hand_entry_before_wall",
                reason="final_hand_entry_not_detected",
            )
        )

    # Final reach: wrists closest to wall before contact
    reach_i = None
    if contact_i is not None and calibration.wall_x is not None:
        seg = np.abs(wrist_x[: contact_i + 1] - calibration.wall_x)
        if np.any(np.isfinite(seg)):
            reach_i = int(np.nanargmin(seg))
    events.append(
        _ev("final_reach", series, reach_i, "wrist_closest_to_wall_before_contact", ["left_wrist", "right_wrist"], 0.7)
        if reach_i is not None
        else RaceEvent.unavailable(event_type="final_reach", method="wrist_closest_to_wall_before_contact", reason="final_reach_not_detected")
    )

    # Glide: low wrist activity / increasing stillness while approaching after final entry
    glide_i = None
    if final_hand_entry is not None and contact_i is not None:
        fi = _idx(frames, final_hand_entry)
        if fi is not None and contact_i > fi:
            glide_i = fi + max(1, (contact_i - fi) // 3)
    events.append(
        _ev("glide_into_wall", series, glide_i, "post_entry_approach_before_contact", ["left_hip", "right_hip"], 0.55)
        if glide_i is not None
        else RaceEvent.unavailable(event_type="glide_into_wall", method="post_entry_approach_before_contact", reason="glide_phase_not_detected")
    )

    # Wall contact
    if not calibration.wall_in_frame:
        events.append(
            RaceEvent.unavailable(
                event_type="wall_contact",
                method="min_distance_to_calibrated_wall",
                reason="wall_outside_frame_exact_contact_not_claimed",
                quality_flags=["wall_outside_view"],
                limitations=["do_not_claim_exact_wall_contact_when_wall_outside_frame"],
            )
        )
    elif blocked or clip_ends_before_contact:
        events.append(
            RaceEvent.unavailable(
                event_type="wall_contact",
                method="min_distance_to_calibrated_wall",
                reason="finish_contact_not_visible" if blocked else "clip_ending_before_wall_contact",
                quality_flags=list(flags_from(blocked, clip_ends_before_contact)),
            )
        )
    elif contact_i is None:
        events.append(
            RaceEvent.unavailable(
                event_type="wall_contact",
                method="min_distance_to_calibrated_wall",
                reason="finish_contact_not_detected",
            )
        )
    else:
        near = float(dist[contact_i]) <= max(40.0, 0.08 * float(calibration.frame_width or 640))
        if not near:
            events.append(
                RaceEvent.unavailable(
                    event_type="wall_contact",
                    method="min_distance_to_calibrated_wall",
                    reason="finish_contact_not_visible",
                    limitations=["swimmer_did_not_reach_wall_in_frame"],
                )
            )
        else:
            qflags = []
            if stroke_hint in {"butterfly", "breaststroke"}:
                qflags.append("two_hand_touch_expected")
            events.append(
                _ev(
                    "wall_contact",
                    series,
                    contact_i,
                    "min_distance_to_calibrated_wall",
                    ["left_wrist", "right_wrist"],
                    min(0.95, 0.55 + 0.4 * calibration.confidence),
                    qflags,
                )
            )

    # Shortened/added stroke estimate — observational only, never measured fact
    if len(pre_entries) >= 3:
        durs = np.diff(sorted(pre_entries)[-3:])
        # If last gap much shorter/longer than previous — observational estimate
        if len(durs) >= 2 and durs[-1] < 0.7 * durs[-2]:
            idx = _idx(frames, pre_entries[-1])
            events.append(
                RaceEvent(
                    event_type="shortened_or_added_stroke_estimate",
                    timestamp_ms=float(ts[idx]) if idx is not None else None,
                    frame_number=int(frames[idx]) if idx is not None else pre_entries[-1],
                    confidence=0.4,
                    confidence_label="low",
                    method="cycle_duration_anomaly_before_finish",
                    supporting_frames=[pre_entries[-2], pre_entries[-1]],
                    quality_flags=["observational_estimate", "not_a_measured_fact"],
                    limitations=["speculative_technique_not_presented_as_measured"],
                    value=1,
                    unit="shortened_stroke_flag",
                )
            )
        else:
            events.append(
                RaceEvent.unavailable(
                    event_type="shortened_or_added_stroke_estimate",
                    method="cycle_duration_anomaly_before_finish",
                    reason="no_clear_shortened_or_added_stroke_pattern",
                )
            )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="shortened_or_added_stroke_estimate",
                method="cycle_duration_anomaly_before_finish",
                reason="insufficient_cycles_for_estimate",
            )
        )

    # Head-position observation near finish
    if contact_i is not None and np.isfinite(series["nose_y"][contact_i]):
        events.append(
            RaceEvent(
                event_type="head_position_observation",
                timestamp_ms=float(ts[contact_i]),
                frame_number=int(frames[contact_i]),
                confidence=0.5,
                confidence_label="moderate",
                method="nose_y_at_finish_contact",
                supporting_frames=[int(frames[contact_i])],
                supporting_timestamps_ms=[float(ts[contact_i])],
                supporting_landmarks=["nose"],
                quality_flags=["observational"],
                limitations=["head_position_is_observational_not_coaching_diagnosis"],
                value=float(series["nose_y"][contact_i]),
                unit="px",
            )
        )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="head_position_observation",
                method="nose_y_at_finish_contact",
                reason="head_landmarks_unavailable_at_finish",
            )
        )

    return events


def flags_from(blocked: bool, clip_ends: bool) -> list[str]:
    out = []
    if blocked:
        out.append("blocked")
    if clip_ends:
        out.append("clip_ending_before_wall_contact")
    return out


def _idx(frames: np.ndarray, frame: int) -> int | None:
    hits = np.where(frames == frame)[0]
    return int(hits[0]) if hits.size else None


def _ev(
    name: str,
    series: dict[str, Any],
    idx: int | None,
    method: str,
    landmarks: list[str],
    conf: float,
    qflags: list[str] | None = None,
) -> RaceEvent:
    if idx is None:
        return RaceEvent.unavailable(event_type=name, method=method, reason=f"{name}_not_detected")
    return RaceEvent(
        event_type=name,
        timestamp_ms=float(series["timestamps_ms"][idx]),
        frame_number=int(series["frames"][idx]),
        confidence=float(np.clip(conf, 0, 1)),
        confidence_label=confidence_label(conf),
        method=method,
        supporting_frames=[int(series["frames"][idx])],
        supporting_timestamps_ms=[float(series["timestamps_ms"][idx])],
        supporting_landmarks=landmarks,
        quality_flags=qflags or [],
    )


def _frame(events: list[RaceEvent], name: str) -> int | None:
    for e in events:
        if e.event_type == name:
            return e.frame_number
    return None


def _metric_val(metrics: list[MetricValue], name: str):
    for m in metrics:
        if m.name == name:
            return m.value
    return None


def _compute_finish_metrics(
    events: list[RaceEvent],
    calibration: WallCalibration,
    view_supported: bool,
) -> list[MetricValue]:
    metrics: list[MetricValue] = []
    contact = next((e for e in events if e.event_type == "wall_contact"), None)
    final_entry = next((e for e in events if e.event_type == "final_hand_entry"), None)

    # Finish timing confidence
    if not view_supported:
        metrics.append(
            MetricValue.unavailable(
                name="finish_timing_confidence",
                display_name="Finish timing confidence",
                unit="score_0_1",
                method="calibration_visibility_contact_aggregate",
                reason="view_or_calibration_does_not_support_reliable_finish_analysis",
            )
        )
    else:
        parts = [calibration.confidence]
        if contact and contact.timestamp_ms is not None:
            parts.append(contact.confidence)
        else:
            parts.append(0.0)
        if final_entry and final_entry.timestamp_ms is not None:
            parts.append(final_entry.confidence)
        score = float(np.mean(parts))
        metrics.append(
            MetricValue(
                name="finish_timing_confidence",
                display_name="Finish timing confidence",
                value=score,
                unit="score_0_1",
                confidence=score,
                confidence_label=confidence_label(score),
                classification="estimated",
                method="calibration_visibility_contact_aggregate",
                supporting_frame_numbers=[x for x in (contact.frame_number if contact else None, final_entry.frame_number if final_entry else None) if x is not None],
                supporting_timestamps_ms=[x for x in (contact.timestamp_ms if contact else None, final_entry.timestamp_ms if final_entry else None) if x is not None],
                quality_flags=[],
            )
        )

    # Time from final hand entry to contact
    if (
        view_supported
        and contact
        and contact.timestamp_ms is not None
        and final_entry
        and final_entry.timestamp_ms is not None
    ):
        metrics.append(
            MetricValue(
                name="time_final_hand_entry_to_contact",
                display_name="Time from final hand entry to wall contact",
                value=float(contact.timestamp_ms - final_entry.timestamp_ms),
                unit="ms",
                confidence=min(contact.confidence, final_entry.confidence),
                confidence_label=confidence_label(min(contact.confidence, final_entry.confidence)),
                classification="estimated",
                method="final_hand_entry_to_wall_contact",
                supporting_frame_numbers=[final_entry.frame_number, contact.frame_number],
                supporting_timestamps_ms=[final_entry.timestamp_ms, contact.timestamp_ms],
                quality_flags=[],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="time_final_hand_entry_to_contact",
                display_name="Time from final hand entry to wall contact",
                unit="ms",
                method="final_hand_entry_to_wall_contact",
                reason="missing_final_entry_or_contact",
            )
        )

    # Never fabricate time lost
    metrics.append(
        MetricValue.unavailable(
            name="time_lost",
            display_name="Time lost",
            unit="ms",
            method="requires_documented_comparison_baseline",
            reason="time_lost_requires_documented_comparison_method",
        )
    )
    return metrics

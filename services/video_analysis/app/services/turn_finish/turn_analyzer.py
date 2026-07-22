"""TurnAnalyzer — turn-event framework (Milestone 7)."""

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
from app.utils.logging import get_logger

logger = get_logger("video_analysis.turn")


@dataclass
class TurnAnalysisResult:
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


class TurnAnalyzer:
    """Detect turn events when the view supports reliable wall analysis."""

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
        turn_type_hint: str | None = None,  # flip | open | unknown
        manual_wall_line: dict[str, Any] | None = None,
        pool_geometry: dict[str, Any] | None = None,
        lane_line_termination_x: float | None = None,
        starting_block_x: float | None = None,
        surface_stroke_entry_frames: list[int] | None = None,
        underwater_kick_frames: list[int] | None = None,
        breakout_frame: int | None = None,
        frame_width: int | None = None,
        image_bgr: Any | None = None,
        blocked_by_obstacle: bool = False,
        moving_camera: bool = False,
    ) -> TurnAnalysisResult:
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
            limitations.append("view_does_not_support_reliable_turn_analysis")
        if blocked_by_obstacle:
            flags.append("swimmer_blocked_by_official_or_lane_rope")
            limitations.append("occlusion_by_obstacle")
        if moving_camera:
            flags.append("moving_camera")

        series = _extract_series(smoothed_poses, calibration)
        events = _detect_turn_events(
            series=series,
            calibration=calibration,
            view_supported=view_supported,
            stroke_hint=stroke_hint,
            turn_type_hint=turn_type_hint or "unknown",
            surface_stroke_entry_frames=surface_stroke_entry_frames or [],
            underwater_kick_frames=underwater_kick_frames or [],
            breakout_frame=breakout_frame,
            blocked=blocked_by_obstacle,
        )
        metrics = _compute_turn_metrics(events, calibration, series, view_supported)

        artifacts = write_turn_artifacts(
            output_dir,
            job_id=job_id,
            video_id=video_id,
            kind="turn",
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
            "calibration_confidence": calibration.confidence,
            "wall_contact_frame": _event_frame(events, "wall_contact"),
            "push_off_frame": _event_frame(events, "push_off"),
            "breakout_frame": _event_frame(events, "breakout"),
        }

        result = TurnAnalysisResult(
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
        summary_path = output_dir / "turn_analysis_summary.json"
        summary_path.write_text(json.dumps(result.to_dict(), indent=2), encoding="utf-8")
        artifacts["turn_analysis_summary"] = str(summary_path.resolve())
        result.artifact_paths = artifacts
        logger.info(
            "Turn analysis complete job=%s wall_method=%s contact=%s",
            job_id,
            calibration.method,
            summary.get("wall_contact_frame"),
        )
        return result


def _view_supports_turns(view_hint: str, calibration: WallCalibration) -> bool:
    if view_hint in {"end", "underwater_front"}:
        return False
    if calibration.method == "unavailable":
        return False
    if calibration.confidence < 0.4:
        return False
    return True


def _extract_series(poses: list[dict[str, Any]], calibration: WallCalibration) -> dict[str, Any]:
    ordered = sorted(poses, key=lambda p: (float(p.get("timestamp_ms") or 0), int(p.get("frame_number") or 0)))
    frames, ts, hip_x, wrist_x, ankle_x, nose_y, wrist_y = [], [], [], [], [], [], []
    for p in ordered:
        frames.append(int(p.get("frame_number") or 0))
        ts.append(float(p.get("timestamp_ms") or 0.0))
        hip_x.append(_mid_x(p, "left_hip", "right_hip"))
        wrist_x.append(_mid_x(p, "left_wrist", "right_wrist"))
        ankle_x.append(_mid_x(p, "left_ankle", "right_ankle"))
        _, ny, _, nq = _kp_xy(p, "nose")
        nose_y.append(float(ny) if nq in {"valid", "interpolated"} else np.nan)
        _, wy, _, wq = _kp_xy(p, "left_wrist")
        wrist_y.append(float(wy) if wq in {"valid", "interpolated"} else np.nan)

    hip = np.asarray(hip_x, dtype=np.float64)
    wall = calibration.wall_x
    if wall is None:
        dist = np.full_like(hip, np.nan)
        toward = np.zeros_like(hip)
    else:
        dist = np.abs(hip - wall)
        # Positive when moving toward wall
        d = np.diff(dist, prepend=dist[0])
        toward = -d  # decreasing distance => toward

    return {
        "frames": np.asarray(frames, dtype=np.int32),
        "timestamps_ms": np.asarray(ts, dtype=np.float64),
        "hip_x": hip,
        "wrist_x": np.asarray(wrist_x, dtype=np.float64),
        "ankle_x": np.asarray(ankle_x, dtype=np.float64),
        "nose_y": np.asarray(nose_y, dtype=np.float64),
        "wrist_y": np.asarray(wrist_y, dtype=np.float64),
        "dist_to_wall": dist,
        "toward_wall": toward,
    }


def _mid_x(pose: dict[str, Any], a: str, b: str) -> float:
    xa, _, _, qa = _kp_xy(pose, a)
    xb, _, _, qb = _kp_xy(pose, b)
    vals = [v for v, q in ((xa, qa), (xb, qb)) if q in {"valid", "interpolated"} and np.isfinite(v)]
    return float(np.mean(vals)) if vals else np.nan


def _detect_turn_events(
    *,
    series: dict[str, Any],
    calibration: WallCalibration,
    view_supported: bool,
    stroke_hint: str,
    turn_type_hint: str,
    surface_stroke_entry_frames: list[int],
    underwater_kick_frames: list[int],
    breakout_frame: int | None,
    blocked: bool,
) -> list[RaceEvent]:
    event_names = [
        "approach_begins",
        "final_stroke_before_wall",
        "turn_initiation",
        "wall_contact",
        "foot_placement",
        "push_off",
        "first_underwater_kick",
        "breakout",
        "first_surface_stroke",
    ]
    if not view_supported:
        return [
            RaceEvent.unavailable(
                event_type=n,
                method="turn_framework_view_gate",
                reason="view_or_calibration_does_not_support_reliable_turn_analysis",
            )
            for n in event_names
        ]

    n = len(series["frames"])
    if n < 5:
        return [
            RaceEvent.unavailable(event_type=n, method="turn_framework", reason="insufficient_frames")
            for n in event_names
        ]

    dist = series["dist_to_wall"]
    frames = series["frames"]
    ts = series["timestamps_ms"]
    toward = series["toward_wall"]
    wrist_x = series["wrist_x"]
    ankle_x = series["ankle_x"]
    wall_x = calibration.wall_x
    wall_in_frame = calibration.wall_in_frame

    events: list[RaceEvent] = []

    # Approach begins: sustained motion toward wall
    approach_i = None
    for i in range(2, n):
        if np.isfinite(toward[i]) and toward[i] > 0 and np.nanmean(toward[max(0, i - 3) : i + 1]) > 0:
            approach_i = i
            break
    events.append(_mk_event("approach_begins", series, approach_i, method="distance_to_wall_decreasing", landmarks=["left_hip", "right_hip"]))

    # Final stroke before wall: prefer last surface entry before closest approach
    contact_i = int(np.nanargmin(dist)) if np.any(np.isfinite(dist)) else None
    final_stroke_i = None
    final_stroke_method = "last_wrist_extension_before_closest_approach"
    contact_frame = int(frames[contact_i]) if contact_i is not None else None
    prior_entries = [
        fr for fr in surface_stroke_entry_frames if contact_frame is None or fr < contact_frame
    ]
    if prior_entries:
        target = prior_entries[-1]
        hits = np.where(frames == target)[0]
        if hits.size:
            final_stroke_i = int(hits[0])
            final_stroke_method = "last_surface_entry_before_wall_from_m5"
    if final_stroke_i is None and contact_i is not None and contact_i > 2 and wall_x is not None:
        seg = wrist_x[: contact_i + 1]
        rel = np.abs(seg - series["hip_x"][: contact_i + 1])
        if np.any(np.isfinite(rel)):
            final_stroke_i = int(np.nanargmax(rel))
    events.append(
        _mk_event(
            "final_stroke_before_wall",
            series,
            final_stroke_i,
            method=final_stroke_method,
            landmarks=["left_wrist", "right_wrist"],
        )
    )

    # Turn initiation: slowing toward wall / distance slope flattens before contact
    init_i = None
    if contact_i is not None and contact_i > 3:
        window = toward[max(0, contact_i - 8) : contact_i]
        if window.size:
            # first frame where toward-wall velocity drops below half of approach mean
            thr = 0.5 * max(float(np.nanmean(toward[toward > 0])) if np.any(toward > 0) else 1.0, 1e-3)
            for j, v in enumerate(window):
                if np.isfinite(v) and v < thr:
                    init_i = max(0, contact_i - 8) + j
                    break
            if init_i is None:
                init_i = max(0, contact_i - 3)
    events.append(
        _mk_event(
            "turn_initiation",
            series,
            init_i,
            method="approach_velocity_drop_before_wall",
            landmarks=["left_hip", "right_hip"],
        )
    )

    # Wall contact — ONLY if wall in frame and distance small
    contact_event: RaceEvent
    if not wall_in_frame:
        contact_event = RaceEvent.unavailable(
            event_type="wall_contact",
            method="wall_proximity_and_extremum",
            reason="wall_outside_frame_exact_contact_not_claimed",
            quality_flags=["wall_outside_view"],
            limitations=["do_not_claim_exact_wall_contact_when_wall_outside_frame"],
        )
    elif contact_i is None or blocked:
        contact_event = RaceEvent.unavailable(
            event_type="wall_contact",
            method="wall_proximity_and_extremum",
            reason="wall_contact_not_observable" if blocked else "closest_approach_unavailable",
            quality_flags=["blocked"] if blocked else [],
        )
    else:
        # Require near-wall proximity
        near = float(dist[contact_i]) <= max(40.0, 0.08 * float(calibration.frame_width or 640))
        if not near:
            contact_event = RaceEvent.unavailable(
                event_type="wall_contact",
                method="wall_proximity_and_extremum",
                reason="swimmer_did_not_reach_calibrated_wall_in_clip",
                limitations=["partial_turn_or_clip_ended_before_wall"],
            )
        else:
            # Butterfly/breaststroke two-hand touch observational flag
            qflags = []
            if stroke_hint in {"butterfly", "breaststroke"}:
                qflags.append("two_hand_touch_expected")
            if turn_type_hint == "flip":
                qflags.append("flip_turn")
            elif turn_type_hint == "open":
                qflags.append("open_turn")
            contact_event = _mk_event(
                "wall_contact",
                series,
                contact_i,
                method="min_distance_to_calibrated_wall",
                landmarks=["left_wrist", "right_wrist", "left_ankle", "right_ankle"],
                conf=min(0.95, 0.55 + 0.4 * calibration.confidence),
                qflags=qflags,
            )
    events.append(contact_event)

    # Foot placement (flip): prefer ankles nearest the wall shortly after contact.
    foot_i = None
    if contact_event.frame_number is not None and wall_x is not None and turn_type_hint != "open":
        ci = int(np.where(frames == contact_event.frame_number)[0][0])
        window = list(range(ci, min(n, ci + 8)))
        best = None
        best_d = None
        for j in window:
            if not np.isfinite(ankle_x[j]):
                continue
            d = abs(ankle_x[j] - wall_x)
            if d <= max(45.0, 0.1 * float(calibration.frame_width or 640)):
                if best_d is None or d < best_d - 0.5:
                    best_d = d
                    best = j
        # Prefer a post-contact plant when ankles stay near wall for >1 frame.
        if best is not None and best == ci and len(window) > 2:
            later = [j for j in window[1:] if np.isfinite(ankle_x[j]) and abs(ankle_x[j] - wall_x) <= (best_d or 1e9) + 2.0]
            if later:
                best = later[0]
        foot_i = best
    if foot_i is None:
        events.append(
            RaceEvent.unavailable(
                event_type="foot_placement",
                method="ankle_near_wall_after_contact",
                reason="foot_placement_not_visible_or_not_applicable",
            )
        )
    else:
        events.append(
            _mk_event(
                "foot_placement",
                series,
                foot_i,
                method="ankle_near_wall_after_contact",
                landmarks=["left_ankle", "right_ankle"],
                conf=0.6,
                qflags=["visible_when_confident"],
            )
        )

    # Push-off: distance increases after contact
    push_i = None
    if contact_event.frame_number is not None:
        ci = int(np.where(frames == contact_event.frame_number)[0][0])
        for j in range(ci + 1, min(n, ci + 20)):
            if np.isfinite(dist[j]) and np.isfinite(dist[ci]) and dist[j] > dist[ci] + 8:
                push_i = j
                break
    events.append(
        _mk_event(
            "push_off",
            series,
            push_i,
            method="distance_from_wall_increases_after_contact",
            landmarks=["left_hip", "right_hip"],
        )
        if push_i is not None
        else RaceEvent.unavailable(
            event_type="push_off",
            method="distance_from_wall_increases_after_contact",
            reason="push_off_not_detected",
        )
    )

    # First underwater kick: prefer provided M6 kicks after push-off
    first_kick_frame = None
    push_frame = _event_frame(events, "push_off")
    for kf in sorted(underwater_kick_frames):
        if push_frame is None or kf >= push_frame:
            first_kick_frame = kf
            break
    if first_kick_frame is not None:
        idx = int(np.where(frames == first_kick_frame)[0][0]) if first_kick_frame in set(frames.tolist()) else None
        events.append(
            _mk_event(
                "first_underwater_kick",
                series,
                idx,
                method="post_turn_underwater_kick_from_m6",
                landmarks=["left_ankle", "right_ankle"],
                conf=0.75,
            )
            if idx is not None
            else RaceEvent(
                event_type="first_underwater_kick",
                timestamp_ms=None,
                frame_number=first_kick_frame,
                confidence=0.6,
                confidence_label="moderate",
                method="post_turn_underwater_kick_from_m6",
                supporting_frames=[first_kick_frame],
                supporting_landmarks=["left_ankle", "right_ankle"],
            )
        )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="first_underwater_kick",
                method="post_turn_underwater_kick_from_m6",
                reason="no_post_turn_kick_available",
            )
        )

    # Breakout / first surface stroke from upstream or local heuristics after push
    if breakout_frame is not None:
        idx = int(np.where(frames == breakout_frame)[0][0]) if breakout_frame in set(frames.tolist()) else None
        events.append(
            _mk_event("breakout", series, idx, method="post_turn_breakout_from_m6", landmarks=["left_wrist", "right_wrist"], conf=0.8)
            if idx is not None
            else RaceEvent(
                event_type="breakout",
                timestamp_ms=None,
                frame_number=breakout_frame,
                confidence=0.65,
                confidence_label="moderate",
                method="post_turn_breakout_from_m6",
                supporting_frames=[breakout_frame],
            )
        )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="breakout",
                method="post_turn_breakout_from_m6",
                reason="breakout_not_available",
            )
        )

    first_surface = None
    for fr in sorted(surface_stroke_entry_frames):
        if push_frame is None or fr >= push_frame:
            first_surface = fr
            break
    if first_surface is not None:
        idx = int(np.where(frames == first_surface)[0][0]) if first_surface in set(frames.tolist()) else None
        events.append(
            _mk_event(
                "first_surface_stroke",
                series,
                idx,
                method="first_surface_cycle_after_push_from_m5",
                landmarks=["left_wrist", "right_wrist"],
                conf=0.8,
            )
            if idx is not None
            else RaceEvent(
                event_type="first_surface_stroke",
                timestamp_ms=None,
                frame_number=first_surface,
                confidence=0.65,
                confidence_label="moderate",
                method="first_surface_cycle_after_push_from_m5",
                supporting_frames=[first_surface],
            )
        )
    else:
        events.append(
            RaceEvent.unavailable(
                event_type="first_surface_stroke",
                method="first_surface_cycle_after_push_from_m5",
                reason="no_post_turn_surface_stroke",
            )
        )

    return events


def _mk_event(
    name: str,
    series: dict[str, Any],
    idx: int | None,
    *,
    method: str,
    landmarks: list[str],
    conf: float = 0.7,
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
        limitations=[],
    )


def _event_frame(events: list[RaceEvent] | list[dict[str, Any]], name: str) -> int | None:
    for e in events:
        if isinstance(e, dict):
            if e.get("event_type") == name:
                return e.get("frame_number")
        elif e.event_type == name:
            return e.frame_number
    return None


def _event_ts(events: list[RaceEvent], name: str) -> float | None:
    for e in events:
        if e.event_type == name:
            return e.timestamp_ms
    return None


def _compute_turn_metrics(
    events: list[RaceEvent],
    calibration: WallCalibration,
    series: dict[str, Any],
    view_supported: bool,
) -> list[MetricValue]:
    metrics: list[MetricValue] = []

    def gap(a: str, b: str, name: str, display: str, method: str) -> MetricValue:
        ta, tb = _event_ts(events, a), _event_ts(events, b)
        fa, fb = _event_frame(events, a), _event_frame(events, b)
        if ta is None or tb is None:
            return MetricValue.unavailable(
                name=name,
                display_name=display,
                unit="ms",
                method=method,
                reason=f"missing_{a}_or_{b}",
            )
        return MetricValue(
            name=name,
            display_name=display,
            value=float(tb - ta),
            unit="ms",
            confidence=min(
                next(e.confidence for e in events if e.event_type == a),
                next(e.confidence for e in events if e.event_type == b),
            ),
            confidence_label=confidence_label(
                min(
                    next(e.confidence for e in events if e.event_type == a),
                    next(e.confidence for e in events if e.event_type == b),
                )
            ),
            classification="estimated",
            method=method,
            supporting_timestamps_ms=[ta, tb],
            supporting_frame_numbers=[x for x in (fa, fb) if x is not None],
            quality_flags=[],
        )

    if not view_supported:
        catalog = [
            ("approach_duration", "Approach duration", "ms"),
            ("time_final_stroke_to_wall_contact", "Time from final stroke to wall contact", "ms"),
            ("wall_contact_duration", "Wall-contact duration", "ms"),
            ("time_contact_to_push_off", "Time from contact to push-off", "ms"),
            ("total_turn_duration", "Total turn duration", "ms"),
            ("push_off_angle", "Push-off angle", "deg"),
            ("streamline_alignment_proxy", "Streamline alignment proxy", "score_0_1"),
            ("first_kick_timing", "First-kick timing", "ms"),
            ("post_turn_underwater_duration", "Post-turn underwater duration", "ms"),
            ("post_turn_breakout_timestamp", "Post-turn breakout timestamp", "ms"),
            ("post_turn_kick_count", "Post-turn kick count", "kicks"),
            ("time_lost", "Time lost", "ms"),
        ]
        for name, display, unit in catalog:
            reason = "view_or_calibration_does_not_support_reliable_turn_analysis"
            if name == "time_lost":
                reason = "time_lost_requires_documented_comparison_method"
            metrics.append(
                MetricValue.unavailable(
                    name=name,
                    display_name=display,
                    unit=unit,
                    method="turn_framework",
                    reason=reason,
                )
            )
        return metrics

    # approach duration: approach_begins → wall_contact (or turn_initiation)
    metrics.append(gap("approach_begins", "wall_contact", "approach_duration", "Approach duration", "approach_begins_to_wall_contact"))
    metrics.append(
        gap(
            "final_stroke_before_wall",
            "wall_contact",
            "time_final_stroke_to_wall_contact",
            "Time from final stroke to wall contact",
            "final_stroke_to_wall_contact",
        )
    )

    # wall contact duration: contact → push_off (proxy; not pressure-sensor truth)
    metrics.append(gap("wall_contact", "push_off", "wall_contact_duration", "Wall-contact duration", "contact_to_push_off_proxy"))
    metrics.append(gap("wall_contact", "push_off", "time_contact_to_push_off", "Time from contact to push-off", "contact_to_push_off"))
    metrics.append(gap("approach_begins", "first_surface_stroke", "total_turn_duration", "Total turn duration", "approach_to_first_surface_stroke"))

    # Push-off angle — unavailable without calibrated 3D / side view certainty
    metrics.append(
        MetricValue.unavailable(
            name="push_off_angle",
            display_name="Push-off angle",
            unit="deg",
            method="requires_calibrated_side_view_geometry",
            reason="camera_view_or_calibration_does_not_support_exact_push_off_angle",
        )
    )

    # Streamline alignment proxy after push-off (observational)
    push_f = _event_frame(events, "push_off")
    if push_f is not None:
        idx = int(np.where(series["frames"] == push_f)[0][0])
        hi = min(len(series["frames"]) - 1, idx + 8)
        # residual variance of hip_x path linearity as crude proxy inverted
        hip = series["hip_x"][idx : hi + 1]
        if np.sum(np.isfinite(hip)) >= 3:
            t = np.arange(len(hip))
            mask = np.isfinite(hip)
            coef = np.polyfit(t[mask], hip[mask], 1)
            fit = coef[0] * t + coef[1]
            resid = float(np.nanstd(hip - fit))
            score = float(np.clip(1.0 - resid / 30.0, 0, 1))
            metrics.append(
                MetricValue(
                    name="streamline_alignment_proxy",
                    display_name="Streamline alignment proxy",
                    value=score,
                    unit="score_0_1",
                    confidence=0.55,
                    confidence_label="moderate",
                    classification="observational",
                    method="post_push_hip_trajectory_linearity",
                    supporting_frame_numbers=[int(x) for x in series["frames"][idx : hi + 1]],
                    supporting_timestamps_ms=[float(x) for x in series["timestamps_ms"][idx : hi + 1]],
                    quality_flags=["observational_proxy", "not_a_measured_biomechanical_angle"],
                )
            )
        else:
            metrics.append(
                MetricValue.unavailable(
                    name="streamline_alignment_proxy",
                    display_name="Streamline alignment proxy",
                    unit="score_0_1",
                    method="post_push_hip_trajectory_linearity",
                    reason="insufficient_post_push_landmarks",
                )
            )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="streamline_alignment_proxy",
                display_name="Streamline alignment proxy",
                unit="score_0_1",
                method="post_push_hip_trajectory_linearity",
                reason="push_off_unavailable",
            )
        )

    metrics.append(gap("push_off", "first_underwater_kick", "first_kick_timing", "First-kick timing", "push_off_to_first_kick"))
    metrics.append(gap("push_off", "breakout", "post_turn_underwater_duration", "Post-turn underwater duration", "push_off_to_breakout"))

    br = next((e for e in events if e.event_type == "breakout"), None)
    if br and br.timestamp_ms is not None:
        metrics.append(
            MetricValue(
                name="post_turn_breakout_timestamp",
                display_name="Post-turn breakout timestamp",
                value=br.timestamp_ms,
                unit="ms",
                confidence=br.confidence,
                confidence_label=br.confidence_label,
                classification="estimated",
                method=br.method,
                supporting_timestamps_ms=[br.timestamp_ms],
                supporting_frame_numbers=[br.frame_number] if br.frame_number is not None else [],
                quality_flags=br.quality_flags,
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="post_turn_breakout_timestamp",
                display_name="Post-turn breakout timestamp",
                unit="ms",
                method="post_turn_breakout_from_m6",
                reason="breakout_unavailable",
            )
        )

    # Post-turn kick count: kicks between push and breakout if frames known
    push_f = _event_frame(events, "push_off")
    br_f = _event_frame(events, "breakout")
    kick_ev = next((e for e in events if e.event_type == "first_underwater_kick"), None)
    if push_f is not None and kick_ev and kick_ev.frame_number is not None:
        # At least 1 if first kick exists; full count needs M6 list — store 1+ as estimated floor
        metrics.append(
            MetricValue(
                name="post_turn_kick_count",
                display_name="Post-turn kick count",
                value=1,
                unit="kicks",
                confidence=0.5,
                confidence_label="moderate",
                classification="estimated",
                method="count_of_known_post_turn_kicks_minimum",
                supporting_frame_numbers=[kick_ev.frame_number],
                supporting_timestamps_ms=[kick_ev.timestamp_ms] if kick_ev.timestamp_ms is not None else [],
                quality_flags=["partial_count_without_full_m6_list"],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="post_turn_kick_count",
                display_name="Post-turn kick count",
                unit="kicks",
                method="count_of_known_post_turn_kicks",
                reason="post_turn_kicks_unavailable",
            )
        )

    # Explicitly never fabricate "time lost"
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

"""Butterfly surface metrics from detected cycles (Milestone 5)."""

from __future__ import annotations

from typing import Any

import numpy as np

from app.services.butterfly.cycle_detector import CycleDetectionResult
from app.services.butterfly.signals import ButterflySignals
from app.services.butterfly.types import MetricValue, StrokeEvent, confidence_label


def _cycle_support(cycles: list) -> tuple[list[int], list[float]]:
    frames = []
    ts = []
    for c in cycles:
        frames.extend([c.start_frame, c.end_frame])
        ts.extend([c.start_ms, c.end_ms])
    return frames, ts


def compute_butterfly_metrics(
    *,
    signals: ButterflySignals,
    detection: CycleDetectionResult,
    stroke_hint: str,
    pool_distance_calibrated: bool = False,
) -> list[MetricValue]:
    metrics: list[MetricValue] = []
    cycles = [c for c in detection.cycles if c.complete]
    all_cycles = detection.cycles
    n_complete = len(cycles)
    support_frames, support_ts = _cycle_support(cycles)
    base_conf = _aggregate_confidence(signals, detection, n_complete)

    if stroke_hint not in {"butterfly", "unknown"}:
        reason = f"incorrect_stroke_type:{stroke_hint}"
        for name, display, unit in _metric_catalog():
            metrics.append(
                MetricValue.unavailable(
                    name=name,
                    display_name=display,
                    unit=unit,
                    method="stroke_gate",
                    reason=reason,
                    quality_flags=["stroke_type_mismatch"],
                )
            )
        metrics.extend(_unsupported_metrics(pool_distance_calibrated))
        return metrics

    # 1–2 cycle / stroke count
    metrics.append(
        MetricValue(
            name="complete_stroke_cycle_count",
            display_name="Complete stroke-cycle count",
            value=n_complete,
            unit="cycles",
            confidence=base_conf if n_complete else 0.0,
            confidence_label=confidence_label(base_conf if n_complete else None),
            classification="measured" if n_complete else "unavailable",
            method=detection.method,
            supporting_timestamps_ms=support_ts,
            supporting_frame_numbers=support_frames,
            quality_flags=detection.quality_flags,
            unavailable_reason=None if n_complete else "no_complete_cycles_detected",
        )
    )
    metrics.append(
        MetricValue(
            name="stroke_count",
            display_name="Stroke count",
            value=n_complete,
            unit="strokes",
            confidence=base_conf if n_complete else 0.0,
            confidence_label=confidence_label(base_conf if n_complete else None),
            classification="measured" if n_complete else "unavailable",
            method="complete_cycles_as_butterfly_strokes",
            supporting_timestamps_ms=support_ts,
            supporting_frame_numbers=support_frames,
            quality_flags=detection.quality_flags,
            unavailable_reason=None if n_complete else "no_complete_cycles_detected",
        )
    )

    durations = [c.duration_s for c in cycles]
    if n_complete >= 1:
        avg_dur = float(np.mean(durations))
        metrics.append(
            MetricValue(
                name="average_cycle_duration",
                display_name="Average cycle duration",
                value=avg_dur,
                unit="s",
                confidence=base_conf,
                confidence_label=confidence_label(base_conf),
                classification="measured",
                method="mean_complete_cycle_duration_from_entry_to_entry",
                supporting_timestamps_ms=support_ts,
                supporting_frame_numbers=support_frames,
                quality_flags=[],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="average_cycle_duration",
                display_name="Average cycle duration",
                unit="s",
                method="mean_complete_cycle_duration_from_entry_to_entry",
                reason="no_complete_cycles_detected",
            )
        )

    if n_complete >= 2:
        rate = 60.0 / float(np.mean(durations))
        metrics.append(
            MetricValue(
                name="average_stroke_rate",
                display_name="Average stroke rate",
                value=rate,
                unit="cycles/min",
                confidence=base_conf,
                confidence_label=confidence_label(base_conf),
                classification="measured",
                method="60_over_mean_cycle_duration",
                supporting_timestamps_ms=support_ts,
                supporting_frame_numbers=support_frames,
                quality_flags=[],
            )
        )
        timing_var = float(np.std(durations) / max(np.mean(durations), 1e-6))
        metrics.append(
            MetricValue(
                name="cycle_to_cycle_timing_variability",
                display_name="Cycle-to-cycle timing variability",
                value=timing_var,
                unit="cv",
                confidence=base_conf,
                confidence_label=confidence_label(base_conf),
                classification="measured",
                method="coefficient_of_variation_of_cycle_durations",
                supporting_timestamps_ms=support_ts,
                supporting_frame_numbers=support_frames,
                quality_flags=[],
            )
        )
    else:
        reason = "fewer_than_two_complete_cycles"
        metrics.append(
            MetricValue.unavailable(
                name="average_stroke_rate",
                display_name="Average stroke rate",
                unit="cycles/min",
                method="60_over_mean_cycle_duration",
                reason=reason,
            )
        )
        metrics.append(
            MetricValue.unavailable(
                name="cycle_to_cycle_timing_variability",
                display_name="Cycle-to-cycle timing variability",
                unit="cv",
                method="coefficient_of_variation_of_cycle_durations",
                reason=reason,
            )
        )

    # Left/right entry timing difference
    lr_diffs = []
    lr_frames = []
    lr_ts = []
    for c in cycles:
        if c.left_entry_frame is None or c.right_entry_frame is None:
            continue
        # map frames to timestamps
        try:
            li = int(np.where(signals.frame_numbers == c.left_entry_frame)[0][0])
            ri = int(np.where(signals.frame_numbers == c.right_entry_frame)[0][0])
        except IndexError:
            continue
        lr_diffs.append(abs(float(signals.timestamps_ms[li] - signals.timestamps_ms[ri])))
        lr_frames.extend([c.left_entry_frame, c.right_entry_frame])
        lr_ts.extend([float(signals.timestamps_ms[li]), float(signals.timestamps_ms[ri])])
    if lr_diffs:
        metrics.append(
            MetricValue(
                name="left_right_hand_entry_timing_difference",
                display_name="Left/right hand-entry timing difference",
                value=float(np.mean(lr_diffs)),
                unit="ms",
                confidence=base_conf * 0.9,
                confidence_label=confidence_label(base_conf * 0.9),
                classification="estimated",
                method="mean_abs_left_right_forward_peak_time_difference",
                supporting_timestamps_ms=lr_ts,
                supporting_frame_numbers=lr_frames,
                quality_flags=["per_wrist_peak_proxy"],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="left_right_hand_entry_timing_difference",
                display_name="Left/right hand-entry timing difference",
                unit="ms",
                method="mean_abs_left_right_forward_peak_time_difference",
                reason="insufficient_bilateral_entry_peaks",
            )
        )

    # Hand entry width / shoulder width
    width_ratios = []
    w_frames = []
    w_ts = []
    for c in cycles:
        try:
            i = int(np.where(signals.frame_numbers == c.entry_frame)[0][0])
        except IndexError:
            continue
        sw = float(signals.shoulder_width[i])
        ew = float(signals.entry_width[i])
        if sw > 1e-3 and np.isfinite(ew):
            width_ratios.append(ew / sw)
            w_frames.append(c.entry_frame)
            w_ts.append(float(signals.timestamps_ms[i]))
    if width_ratios and detection.view_suitability >= 0.5:
        metrics.append(
            MetricValue(
                name="hand_entry_width_relative_to_shoulder_width",
                display_name="Hand-entry width relative to shoulder width",
                value=float(np.mean(width_ratios)),
                unit="ratio",
                confidence=base_conf * detection.view_suitability,
                confidence_label=confidence_label(base_conf * detection.view_suitability),
                classification="measured",
                method="mean_entry_wrist_separation_over_shoulder_width",
                supporting_timestamps_ms=w_ts,
                supporting_frame_numbers=w_frames,
                quality_flags=[],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="hand_entry_width_relative_to_shoulder_width",
                display_name="Hand-entry width relative to shoulder width",
                unit="ratio",
                method="mean_entry_wrist_separation_over_shoulder_width",
                reason="insufficient_entry_width_samples_or_unsuitable_view",
            )
        )

    # Recovery symmetry (observational)
    sym_vals = []
    for c in cycles:
        if c.recovery_frame is None:
            continue
        try:
            i = int(np.where(signals.frame_numbers == c.recovery_frame)[0][0])
        except IndexError:
            continue
        if np.isfinite(signals.bilateral_sync[i]):
            sym_vals.append(float(signals.bilateral_sync[i]))
    if sym_vals:
        metrics.append(
            MetricValue(
                name="recovery_symmetry",
                display_name="Recovery symmetry",
                value=float(np.mean(sym_vals)),
                unit="score_0_1",
                confidence=base_conf * 0.75,
                confidence_label=confidence_label(base_conf * 0.75),
                classification="observational",
                method="mean_bilateral_wrist_sync_at_recovery_onset",
                supporting_timestamps_ms=support_ts,
                supporting_frame_numbers=support_frames,
                quality_flags=["observational_proxy"],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="recovery_symmetry",
                display_name="Recovery symmetry",
                unit="score_0_1",
                method="mean_bilateral_wrist_sync_at_recovery_onset",
                reason="recovery_phase_not_detected",
            )
        )

    # Breathing metrics
    breath_events = [e for e in detection.events if e.event_type == "breath_estimate"]
    metrics.extend(_breathing_metrics(breath_events, cycles, signals, base_conf, detection))

    # Head position stability
    if np.any(signals.head_visible > 0) and np.any(np.isfinite(signals.head_elevation)):
        elev = signals.head_elevation[np.isfinite(signals.head_elevation)]
        # Normalize by shoulder width median for scale-free stability
        sw = np.nanmedian(signals.shoulder_width)
        scale = sw if sw and sw > 1e-3 else 1.0
        stability = float(np.std(elev) / scale)
        h_conf = float(np.mean(signals.head_visible)) * base_conf
        metrics.append(
            MetricValue(
                name="head_position_stability",
                display_name="Head-position stability",
                value=stability,
                unit="shoulder_widths_std",
                confidence=h_conf,
                confidence_label=confidence_label(h_conf),
                classification="estimated",
                method="std_nose_elevation_over_median_shoulder_width",
                supporting_timestamps_ms=signals.timestamps_ms[:: max(1, len(signals.timestamps_ms) // 8)].tolist(),
                supporting_frame_numbers=signals.frame_numbers[:: max(1, len(signals.frame_numbers) // 8)].tolist(),
                quality_flags=["lower_is_more_stable"],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="head_position_stability",
                display_name="Head-position stability",
                unit="shoulder_widths_std",
                method="std_nose_elevation_over_median_shoulder_width",
                reason="head_landmarks_unavailable",
            )
        )

    # Late-clip changes
    metrics.extend(_late_clip_metrics(cycles, base_conf))

    metrics.extend(_unsupported_metrics(pool_distance_calibrated))
    return metrics


def _breathing_metrics(
    breath_events: list[StrokeEvent],
    cycles: list,
    signals: ButterflySignals,
    base_conf: float,
    detection: CycleDetectionResult,
) -> list[MetricValue]:
    out: list[MetricValue] = []
    b_frames = [e.frame_number for e in breath_events]
    b_ts = [e.timestamp_ms for e in breath_events]
    b_conf = float(np.mean([e.confidence for e in breath_events])) if breath_events else 0.0

    if breath_events:
        out.append(
            MetricValue(
                name="breathing_event_estimate",
                display_name="Breathing-event estimate",
                value=len(breath_events),
                unit="events",
                confidence=b_conf,
                confidence_label=confidence_label(b_conf),
                classification="estimated",
                method="head_elevation_peaks_above_shoulders",
                supporting_timestamps_ms=b_ts,
                supporting_frame_numbers=b_frames,
                quality_flags=["breath_estimate"],
            )
        )
    else:
        out.append(
            MetricValue.unavailable(
                name="breathing_event_estimate",
                display_name="Breathing-event estimate",
                unit="events",
                method="head_elevation_peaks_above_shoulders",
                reason="no_breath_peaks_detected",
            )
        )

    if breath_events and len(signals.timestamps_s) >= 2:
        duration_min = max(
            (float(signals.timestamps_s[-1] - signals.timestamps_s[0]) / 60.0),
            1e-6,
        )
        freq = len(breath_events) / duration_min
        out.append(
            MetricValue(
                name="breathing_frequency",
                display_name="Breathing frequency",
                value=freq,
                unit="breaths/min",
                confidence=b_conf * 0.9,
                confidence_label=confidence_label(b_conf * 0.9),
                classification="estimated",
                method="breath_events_over_clip_duration_minutes",
                supporting_timestamps_ms=b_ts,
                supporting_frame_numbers=b_frames,
                quality_flags=["breath_estimate"],
            )
        )
    else:
        out.append(
            MetricValue.unavailable(
                name="breathing_frequency",
                display_name="Breathing frequency",
                unit="breaths/min",
                method="breath_events_over_clip_duration_minutes",
                reason="no_breath_peaks_detected",
            )
        )

    # Breath timing within cycle (phase 0-1)
    phases = []
    p_frames = []
    p_ts = []
    for e in breath_events:
        for c in cycles:
            if c.start_frame <= e.frame_number <= c.end_frame and c.duration_s > 0:
                phase = (e.timestamp_ms - c.start_ms) / (c.duration_s * 1000.0)
                phases.append(float(np.clip(phase, 0, 1)))
                p_frames.append(e.frame_number)
                p_ts.append(e.timestamp_ms)
                break
    if phases:
        out.append(
            MetricValue(
                name="breath_timing_within_stroke_cycle",
                display_name="Breath timing within the stroke cycle",
                value=float(np.mean(phases)),
                unit="cycle_phase_0_1",
                confidence=b_conf * base_conf,
                confidence_label=confidence_label(b_conf * base_conf),
                classification="estimated",
                method="mean_breath_phase_within_enclosing_cycle",
                supporting_timestamps_ms=p_ts,
                supporting_frame_numbers=p_frames,
                quality_flags=["breath_estimate"],
            )
        )
    else:
        out.append(
            MetricValue.unavailable(
                name="breath_timing_within_stroke_cycle",
                display_name="Breath timing within the stroke cycle",
                unit="cycle_phase_0_1",
                method="mean_breath_phase_within_enclosing_cycle",
                reason="breath_events_not_aligned_to_complete_cycles",
            )
        )
    return out


def _late_clip_metrics(cycles: list, base_conf: float) -> list[MetricValue]:
    out: list[MetricValue] = []
    if len(cycles) < 4:
        reason = "need_at_least_four_complete_cycles_for_late_clip_comparison"
        out.append(
            MetricValue.unavailable(
                name="late_clip_stroke_rate_change",
                display_name="Late-clip stroke-rate change",
                unit="cycles/min",
                method="second_half_rate_minus_first_half_rate",
                reason=reason,
            )
        )
        out.append(
            MetricValue.unavailable(
                name="late_clip_timing_consistency_change",
                display_name="Late-clip timing-consistency change",
                unit="cv_delta",
                method="second_half_duration_cv_minus_first_half_cv",
                reason=reason,
            )
        )
        return out

    mid = len(cycles) // 2
    first = [c.duration_s for c in cycles[:mid]]
    second = [c.duration_s for c in cycles[mid:]]
    rate1 = 60.0 / float(np.mean(first))
    rate2 = 60.0 / float(np.mean(second))
    cv1 = float(np.std(first) / max(np.mean(first), 1e-6))
    cv2 = float(np.std(second) / max(np.mean(second), 1e-6))
    frames, ts = _cycle_support(cycles)
    conf = base_conf * 0.85
    out.append(
        MetricValue(
            name="late_clip_stroke_rate_change",
            display_name="Late-clip stroke-rate change",
            value=rate2 - rate1,
            unit="cycles/min",
            confidence=conf,
            confidence_label=confidence_label(conf),
            classification="measured",
            method="second_half_rate_minus_first_half_rate",
            supporting_timestamps_ms=ts,
            supporting_frame_numbers=frames,
            quality_flags=["half_split_by_cycle_count"],
        )
    )
    out.append(
        MetricValue(
            name="late_clip_timing_consistency_change",
            display_name="Late-clip timing-consistency change",
            value=cv2 - cv1,
            unit="cv_delta",
            confidence=conf,
            confidence_label=confidence_label(conf),
            classification="measured",
            method="second_half_duration_cv_minus_first_half_cv",
            supporting_timestamps_ms=ts,
            supporting_frame_numbers=frames,
            quality_flags=["half_split_by_cycle_count", "positive_means_less_consistent"],
        )
    )
    return out


def _unsupported_metrics(pool_distance_calibrated: bool) -> list[MetricValue]:
    out = []
    if not pool_distance_calibrated:
        out.append(
            MetricValue.unavailable(
                name="distance_per_stroke",
                display_name="Distance per stroke",
                unit="m/stroke",
                method="requires_validated_pool_distance_calibration",
                reason="pool_distance_calibration_not_validated",
            )
        )
    out.append(
        MetricValue.unavailable(
            name="exact_elbow_angle",
            display_name="Exact elbow angle",
            unit="deg",
            method="3d_angle_requires_calibrated_view",
            reason="camera_view_does_not_support_exact_biomechanical_angles",
        )
    )
    out.append(
        MetricValue.unavailable(
            name="exact_shoulder_angle",
            display_name="Exact shoulder angle",
            unit="deg",
            method="3d_angle_requires_calibrated_view",
            reason="camera_view_does_not_support_exact_biomechanical_angles",
        )
    )
    return out


def _aggregate_confidence(
    signals: ButterflySignals,
    detection: CycleDetectionResult,
    n_complete: int,
) -> float:
    if len(signals.pose_confidence) == 0:
        return 0.0
    cycle_consistency = 1.0
    durs = [c.duration_s for c in detection.cycles if c.complete]
    if len(durs) >= 2:
        cv = float(np.std(durs) / max(np.mean(durs), 1e-6))
        cycle_consistency = float(np.clip(1.0 - cv, 0.0, 1.0))
    support = float(np.clip(n_complete / 4.0, 0.0, 1.0))
    parts = [
        float(np.nanmean(signals.wrist_visible)),
        float(np.nanmean(signals.shoulder_visible)),
        float(np.nanmean(signals.head_visible)) * 0.5 + 0.5,
        cycle_consistency,
        float(np.nanmean(signals.track_confidence)),
        float(np.nanmean(signals.pose_confidence)),
        support,
        float(detection.view_suitability),
    ]
    return float(np.clip(np.mean(parts), 0.0, 1.0))


def _metric_catalog() -> list[tuple[str, str, str | None]]:
    return [
        ("complete_stroke_cycle_count", "Complete stroke-cycle count", "cycles"),
        ("stroke_count", "Stroke count", "strokes"),
        ("average_cycle_duration", "Average cycle duration", "s"),
        ("average_stroke_rate", "Average stroke rate", "cycles/min"),
        ("cycle_to_cycle_timing_variability", "Cycle-to-cycle timing variability", "cv"),
        ("left_right_hand_entry_timing_difference", "Left/right hand-entry timing difference", "ms"),
        ("hand_entry_width_relative_to_shoulder_width", "Hand-entry width relative to shoulder width", "ratio"),
        ("recovery_symmetry", "Recovery symmetry", "score_0_1"),
        ("breathing_event_estimate", "Breathing-event estimate", "events"),
        ("breathing_frequency", "Breathing frequency", "breaths/min"),
        ("breath_timing_within_stroke_cycle", "Breath timing within the stroke cycle", "cycle_phase_0_1"),
        ("head_position_stability", "Head-position stability", "shoulder_widths_std"),
        ("late_clip_stroke_rate_change", "Late-clip stroke-rate change", "cycles/min"),
        ("late_clip_timing_consistency_change", "Late-clip timing-consistency change", "cv_delta"),
    ]

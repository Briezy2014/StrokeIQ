"""Underwater / breakout metrics (Milestone 6)."""

from __future__ import annotations

import numpy as np

from app.services.underwater.detector import UnderwaterDetectionResult
from app.services.underwater.signals import UnderwaterSignals
from app.services.underwater.types import MetricValue, confidence_label


def compute_underwater_metrics(
    *,
    signals: UnderwaterSignals,
    detection: UnderwaterDetectionResult,
    pool_distance_calibrated: bool = False,
) -> list[MetricValue]:
    metrics: list[MetricValue] = []
    phase = detection.phase
    kicks = [e for e in detection.events if e.event_type == "dolphin_kick"]
    breakout = next((e for e in detection.events if e.event_type == "breakout"), None)
    first_stroke = next((e for e in detection.events if e.event_type == "first_surface_stroke"), None)

    support_frames = []
    support_ts = []
    if phase:
        support_frames = [phase.start_frame, phase.end_frame]
        support_ts = [phase.start_ms, phase.end_ms]
    support_frames.extend(detection.kick_frames)
    for e in detection.events:
        support_ts.append(e.timestamp_ms)

    quality = _quality_score(signals, detection)
    metrics.append(
        MetricValue(
            name="underwater_analysis_quality_score",
            display_name="Underwater-analysis quality score",
            value=quality,
            unit="score_0_1",
            confidence=quality,
            confidence_label=confidence_label(quality),
            classification="estimated",
            method="visibility_phase_kick_view_aggregate",
            supporting_timestamps_ms=support_ts[:8],
            supporting_frame_numbers=support_frames[:8],
            quality_flags=detection.quality_flags,
        )
    )

    if phase is None:
        reason = "no_valid_underwater_phase"
        for name, display, unit, method in _core_catalog():
            metrics.append(
                MetricValue.unavailable(
                    name=name,
                    display_name=display,
                    unit=unit,
                    method=method,
                    reason=reason,
                    quality_flags=detection.quality_flags,
                )
            )
        metrics.append(_breakout_distance(None, pool_distance_calibrated))
        return metrics

    metrics.append(
        MetricValue(
            name="underwater_duration",
            display_name="Underwater duration",
            value=phase.duration_s,
            unit="s",
            confidence=phase.confidence,
            confidence_label=confidence_label(phase.confidence),
            classification="measured",
            method="underwater_phase_end_minus_start",
            supporting_timestamps_ms=[phase.start_ms, phase.end_ms],
            supporting_frame_numbers=[phase.start_frame, phase.end_frame],
            quality_flags=phase.quality_flags,
        )
    )

    if breakout is not None:
        metrics.append(
            MetricValue(
                name="breakout_timestamp",
                display_name="Breakout timestamp",
                value=breakout.timestamp_ms,
                unit="ms",
                confidence=breakout.confidence,
                confidence_label=breakout.confidence_label,
                classification="estimated",
                method=breakout.method,
                supporting_timestamps_ms=[breakout.timestamp_ms],
                supporting_frame_numbers=[breakout.frame_number],
                quality_flags=breakout.quality_flags,
            )
        )
        metrics.append(
            MetricValue(
                name="breakout_confidence",
                display_name="Breakout confidence",
                value=breakout.confidence,
                unit="score_0_1",
                confidence=breakout.confidence,
                confidence_label=breakout.confidence_label,
                classification="estimated",
                method=breakout.method,
                supporting_timestamps_ms=[breakout.timestamp_ms],
                supporting_frame_numbers=[breakout.frame_number],
                quality_flags=breakout.quality_flags,
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="breakout_timestamp",
                display_name="Breakout timestamp",
                unit="ms",
                method="wrist_activity_rise+depth_drop+surface_stroke_gate",
                reason="breakout_not_detected",
            )
        )
        metrics.append(
            MetricValue.unavailable(
                name="breakout_confidence",
                display_name="Breakout confidence",
                unit="score_0_1",
                method="wrist_activity_rise+depth_drop+surface_stroke_gate",
                reason="breakout_not_detected",
            )
        )

    if first_stroke is not None:
        metrics.append(
            MetricValue(
                name="first_surface_stroke_timestamp",
                display_name="First surface-stroke timestamp",
                value=first_stroke.timestamp_ms,
                unit="ms",
                confidence=first_stroke.confidence,
                confidence_label=first_stroke.confidence_label,
                classification="measured" if "butterfly" in first_stroke.method else "estimated",
                method=first_stroke.method,
                supporting_timestamps_ms=[first_stroke.timestamp_ms],
                supporting_frame_numbers=[first_stroke.frame_number],
                quality_flags=first_stroke.quality_flags,
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="first_surface_stroke_timestamp",
                display_name="First surface-stroke timestamp",
                unit="ms",
                method="first_validated_butterfly_cycle_entry_after_underwater",
                reason="no_surface_stroke_cycle_available",
            )
        )

    if kicks:
        metrics.append(
            MetricValue(
                name="estimated_underwater_kick_count",
                display_name="Estimated underwater kick count",
                value=len(kicks),
                unit="kicks",
                confidence=float(np.mean([k.confidence for k in kicks])),
                confidence_label=confidence_label(float(np.mean([k.confidence for k in kicks]))),
                classification="estimated",
                method="ankle_oscillation_peaks_in_underwater_phase",
                supporting_timestamps_ms=[k.timestamp_ms for k in kicks],
                supporting_frame_numbers=[k.frame_number for k in kicks],
                quality_flags=["estimated_count"],
            )
        )
        if phase.duration_s > 1e-6:
            freq = len(kicks) / (phase.duration_s / 60.0)
            metrics.append(
                MetricValue(
                    name="kick_frequency",
                    display_name="Kick frequency",
                    value=freq,
                    unit="kicks/min",
                    confidence=float(np.mean([k.confidence for k in kicks])),
                    confidence_label=confidence_label(float(np.mean([k.confidence for k in kicks]))),
                    classification="estimated",
                    method="kick_count_over_underwater_duration_minutes",
                    supporting_timestamps_ms=[k.timestamp_ms for k in kicks],
                    supporting_frame_numbers=[k.frame_number for k in kicks],
                    quality_flags=[],
                )
            )
        else:
            metrics.append(
                MetricValue.unavailable(
                    name="kick_frequency",
                    display_name="Kick frequency",
                    unit="kicks/min",
                    method="kick_count_over_underwater_duration_minutes",
                    reason="underwater_duration_invalid",
                )
            )
        first_kick = min(kicks, key=lambda k: k.timestamp_ms)
        metrics.append(
            MetricValue(
                name="first_kick_timing",
                display_name="First-kick timing",
                value=first_kick.timestamp_ms - phase.start_ms,
                unit="ms",
                confidence=first_kick.confidence,
                confidence_label=first_kick.confidence_label,
                classification="estimated",
                method="first_kick_minus_underwater_start",
                supporting_timestamps_ms=[phase.start_ms, first_kick.timestamp_ms],
                supporting_frame_numbers=[phase.start_frame, first_kick.frame_number],
                quality_flags=[],
            )
        )
    else:
        reason = "no_kicks_detected_or_feet_obscured"
        if "feet_obscured" in detection.quality_flags:
            reason = "feet_obscured"
        for name, display, unit, method in [
            ("estimated_underwater_kick_count", "Estimated underwater kick count", "kicks", "ankle_oscillation_peaks_in_underwater_phase"),
            ("kick_frequency", "Kick frequency", "kicks/min", "kick_count_over_underwater_duration_minutes"),
            ("first_kick_timing", "First-kick timing", "ms", "first_kick_minus_underwater_start"),
        ]:
            metrics.append(
                MetricValue.unavailable(
                    name=name,
                    display_name=display,
                    unit=unit,
                    method=method,
                    reason=reason,
                    quality_flags=detection.quality_flags,
                )
            )

    if kicks and first_stroke is not None:
        last_kick = max(kicks, key=lambda k: k.timestamp_ms)
        metrics.append(
            MetricValue(
                name="time_between_final_kick_and_first_stroke",
                display_name="Time between final kick and first stroke",
                value=first_stroke.timestamp_ms - last_kick.timestamp_ms,
                unit="ms",
                confidence=min(last_kick.confidence, first_stroke.confidence),
                confidence_label=confidence_label(min(last_kick.confidence, first_stroke.confidence)),
                classification="estimated",
                method="first_surface_stroke_minus_final_kick",
                supporting_timestamps_ms=[last_kick.timestamp_ms, first_stroke.timestamp_ms],
                supporting_frame_numbers=[last_kick.frame_number, first_stroke.frame_number],
                quality_flags=[],
            )
        )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="time_between_final_kick_and_first_stroke",
                display_name="Time between final kick and first stroke",
                unit="ms",
                method="first_surface_stroke_minus_final_kick",
                reason="missing_final_kick_or_first_surface_stroke",
            )
        )

    # Body-line consistency proxy during underwater
    res = signals.body_line_residual
    if phase and np.any(np.isfinite(res)):
        # map phase frames to indices
        try:
            i0 = int(np.where(signals.frame_numbers == phase.start_frame)[0][0])
            i1 = int(np.where(signals.frame_numbers == phase.end_frame)[0][0])
            seg = res[i0 : i1 + 1]
            seg = seg[np.isfinite(seg)]
            if seg.size:
                # lower residual => more consistent; invert to 0..1 score
                score = float(np.clip(1.0 - (np.mean(seg) / max(np.nanmedian(signals.bbox_h), 1.0)), 0, 1))
                metrics.append(
                    MetricValue(
                        name="underwater_body_line_consistency_proxy",
                        display_name="Underwater body-line consistency proxy",
                        value=score,
                        unit="score_0_1",
                        confidence=phase.confidence * 0.8,
                        confidence_label=confidence_label(phase.confidence * 0.8),
                        classification="observational",
                        method="shoulder_hip_ankle_colinearity_residual_inverted",
                        supporting_timestamps_ms=[phase.start_ms, phase.end_ms],
                        supporting_frame_numbers=[phase.start_frame, phase.end_frame],
                        quality_flags=["observational_proxy"],
                    )
                )
            else:
                metrics.append(
                    MetricValue.unavailable(
                        name="underwater_body_line_consistency_proxy",
                        display_name="Underwater body-line consistency proxy",
                        unit="score_0_1",
                        method="shoulder_hip_ankle_colinearity_residual_inverted",
                        reason="insufficient_body_landmarks",
                    )
                )
        except IndexError:
            metrics.append(
                MetricValue.unavailable(
                    name="underwater_body_line_consistency_proxy",
                    display_name="Underwater body-line consistency proxy",
                    unit="score_0_1",
                    method="shoulder_hip_ankle_colinearity_residual_inverted",
                    reason="phase_frame_index_mismatch",
                )
            )
    else:
        metrics.append(
            MetricValue.unavailable(
                name="underwater_body_line_consistency_proxy",
                display_name="Underwater body-line consistency proxy",
                unit="score_0_1",
                method="shoulder_hip_ankle_colinearity_residual_inverted",
                reason="insufficient_body_landmarks",
            )
        )

    metrics.append(_breakout_distance(breakout, pool_distance_calibrated))
    return metrics


def _breakout_distance(breakout, calibrated: bool) -> MetricValue:
    if not calibrated:
        return MetricValue.unavailable(
            name="breakout_distance",
            display_name="Breakout distance",
            unit="m",
            method="requires_validated_pool_distance_calibration",
            reason="pool_distance_calibration_not_validated",
        )
    # Calibration flag alone is not enough without a validated scale factor in this milestone.
    return MetricValue.unavailable(
        name="breakout_distance",
        display_name="Breakout distance",
        unit="m",
        method="pixels_to_meters_requires_validated_scale",
        reason="pool_scale_factor_not_available",
        quality_flags=["calibration_flag_set_but_scale_missing"],
    )


def _quality_score(signals: UnderwaterSignals, detection: UnderwaterDetectionResult) -> float:
    if len(signals.pose_confidence) == 0:
        return 0.0
    parts = [
        float(np.nanmean(signals.pose_confidence)),
        float(np.nanmean(signals.hip_visible)),
        float(np.nanmean(1.0 - 0.5 * signals.feet_obscured)),
        0.8 if detection.phase is not None else 0.2,
        0.7 if detection.kick_frames else 0.4,
        0.8 if detection.breakout_frame is not None else 0.3,
        0.3 if detection.view_mode in {"deck", "end"} else 0.7,
    ]
    return float(np.clip(np.mean(parts), 0, 1))


def _core_catalog() -> list[tuple[str, str, str | None, str]]:
    return [
        ("underwater_duration", "Underwater duration", "s", "underwater_phase_end_minus_start"),
        ("breakout_timestamp", "Breakout timestamp", "ms", "wrist_activity_rise+depth_drop+surface_stroke_gate"),
        ("breakout_confidence", "Breakout confidence", "score_0_1", "wrist_activity_rise+depth_drop+surface_stroke_gate"),
        ("first_surface_stroke_timestamp", "First surface-stroke timestamp", "ms", "first_validated_butterfly_cycle_entry_after_underwater"),
        ("estimated_underwater_kick_count", "Estimated underwater kick count", "kicks", "ankle_oscillation_peaks_in_underwater_phase"),
        ("kick_frequency", "Kick frequency", "kicks/min", "kick_count_over_underwater_duration_minutes"),
        ("first_kick_timing", "First-kick timing", "ms", "first_kick_minus_underwater_start"),
        ("time_between_final_kick_and_first_stroke", "Time between final kick and first stroke", "ms", "first_surface_stroke_minus_final_kick"),
        ("underwater_body_line_consistency_proxy", "Underwater body-line consistency proxy", "score_0_1", "shoulder_hip_ankle_colinearity_residual_inverted"),
    ]

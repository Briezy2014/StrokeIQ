"""Domain metric name constants — Milestone 5 surface butterfly."""

# Surface-stroke metrics implemented in Milestone 5.
BUTTERFLY_SURFACE_METRICS = (
    "complete_stroke_cycle_count",
    "stroke_count",
    "average_cycle_duration",
    "average_stroke_rate",
    "cycle_to_cycle_timing_variability",
    "left_right_hand_entry_timing_difference",
    "hand_entry_width_relative_to_shoulder_width",
    "recovery_symmetry",
    "breathing_event_estimate",
    "breathing_frequency",
    "breath_timing_within_stroke_cycle",
    "head_position_stability",
    "late_clip_stroke_rate_change",
    "late_clip_timing_consistency_change",
)

UNDERWATER_M6_METRICS = (
    "underwater_duration",
    "breakout_timestamp",
    "first_surface_stroke_timestamp",
    "estimated_underwater_kick_count",
    "kick_frequency",
    "first_kick_timing",
    "time_between_final_kick_and_first_stroke",
    "underwater_body_line_consistency_proxy",
    "breakout_confidence",
    "underwater_analysis_quality_score",
)

# Legacy combined list (surface + underwater names).
BUTTERFLY_M1_METRICS = BUTTERFLY_SURFACE_METRICS + UNDERWATER_M6_METRICS

# Explicitly unavailable in M5 (no pool calibration / unsupported views).
BUTTERFLY_M5_UNSUPPORTED = (
    "distance_per_stroke",
    "exact_elbow_angle",
    "exact_shoulder_angle",
)

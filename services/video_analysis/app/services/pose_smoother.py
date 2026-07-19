"""Temporal pose validation and smoothing (Milestone 4).

Preserves raw RTMPose output unchanged and emits a separate smoothed dataset.
Filtering method: confidence-weighted gap fill (short gaps only) + outlier
rejection via velocity/acceleration limits + Savitzky–Golay temporal filter
on valid segments.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass, field
from typing import Any, Literal

import numpy as np
from scipy.signal import savgol_filter

from app.domain.landmarks import COCO_WHOLEBODY_KEYPOINT_NAMES, CORE_BODY_INDICES

QualityFlag = Literal[
    "valid",
    "low_confidence",
    "interpolated",
    "outlier_removed",
    "occluded",
    "unavailable",
]


@dataclass
class SmoothingParams:
    min_keypoint_confidence: float = 0.30
    max_interpolation_gap_frames: int = 3
    # Velocity/acceleration use timestamps (supports variable frame rate).
    max_joint_velocity_px_s: float = 2500.0
    # High enough to tolerate small keypoint jitter; teleports still fail velocity/continuity.
    max_joint_acceleration_px_s2: float = 80000.0
    # Hard per-nominal-frame continuity ceiling (teleport detection).
    # Scaled by elapsed time so subsampled / VFR clips are not over-rejected.
    continuity_max_jump_px: float = 100.0
    savgol_window: int = 5
    savgol_polyorder: int = 2
    long_occlusion_gap_frames: int = 8
    usable_frame_min_core_joints: int = 4
    usable_frame_min_confidence: float = 0.20


@dataclass
class PoseCoverageStats:
    pose_coverage_percentage: float
    usable_frame_percentage: float
    keypoint_availability_percentage: float
    longest_missing_interval_frames: int
    average_pose_confidence: float
    swimmer_tracking_overlap_percentage: float
    total_frames: int
    usable_frames: int
    frames_with_any_valid_keypoint: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "pose_coverage_percentage": self.pose_coverage_percentage,
            "usable_frame_percentage": self.usable_frame_percentage,
            "keypoint_availability_percentage": self.keypoint_availability_percentage,
            "longest_missing_interval_frames": self.longest_missing_interval_frames,
            "average_pose_confidence": self.average_pose_confidence,
            "swimmer_tracking_overlap_percentage": self.swimmer_tracking_overlap_percentage,
            "total_frames": self.total_frames,
            "usable_frames": self.usable_frames,
            "frames_with_any_valid_keypoint": self.frames_with_any_valid_keypoint,
        }


@dataclass
class SmoothPoseResult:
    raw_poses: list[dict[str, Any]]
    smoothed_poses: list[dict[str, Any]]
    frame_confidence: list[dict[str, Any]]
    coverage: PoseCoverageStats
    params: dict[str, Any]
    filter_method: str
    limitations: list[str] = field(default_factory=list)


def preserve_raw_poses(poses: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Deep-copy raw poses so later stages cannot mutate Milestone 3 output."""
    return copy.deepcopy(poses)


def smooth_pose_sequence(
    raw_poses: list[dict[str, Any]],
    *,
    params: SmoothingParams | None = None,
    tracked_frame_numbers: set[int] | None = None,
) -> SmoothPoseResult:
    """
    Build a smoothed pose dataset from raw pose dicts.

    Never interpolates across gaps longer than max_interpolation_gap_frames.
    Never invents coordinates from low-confidence noise.
    """
    params = params or SmoothingParams()
    raw = preserve_raw_poses(raw_poses)
    if not raw:
        empty_stats = PoseCoverageStats(
            pose_coverage_percentage=0.0,
            usable_frame_percentage=0.0,
            keypoint_availability_percentage=0.0,
            longest_missing_interval_frames=0,
            average_pose_confidence=0.0,
            swimmer_tracking_overlap_percentage=0.0,
            total_frames=0,
            usable_frames=0,
            frames_with_any_valid_keypoint=0,
        )
        return SmoothPoseResult(
            raw_poses=raw,
            smoothed_poses=[],
            frame_confidence=[],
            coverage=empty_stats,
            params=params.__dict__.copy(),
            filter_method=_filter_method_name(),
            limitations=["No raw poses provided"],
        )

    # Sort by frame number for temporal processing
    ordered = sorted(raw, key=lambda p: _safe_frame_number(p))
    n = len(ordered)
    k = len(COCO_WHOLEBODY_KEYPOINT_NAMES)

    xs = np.full((n, k), np.nan, dtype=np.float64)
    ys = np.full((n, k), np.nan, dtype=np.float64)
    confs = np.zeros((n, k), dtype=np.float64)
    flags: list[list[QualityFlag]] = [["unavailable"] * k for _ in range(n)]

    for i, pose in enumerate(ordered):
        kps = pose.get("keypoints") or []
        for j, name in enumerate(COCO_WHOLEBODY_KEYPOINT_NAMES):
            kp = kps[j] if j < len(kps) else None
            if not isinstance(kp, dict):
                flags[i][j] = "unavailable"
                continue
            conf = float(kp.get("confidence") or 0.0)
            confs[i, j] = conf
            x, y = kp.get("x"), kp.get("y")
            if x is None or y is None or conf < params.min_keypoint_confidence:
                flags[i][j] = "low_confidence" if conf > 0 else "unavailable"
                continue
            xs[i, j] = float(x)
            ys[i, j] = float(y)
            flags[i][j] = "valid"

    # Mark occluded frames from raw unusable reasons / quality flags
    for i, pose in enumerate(ordered):
        reason = pose.get("unusable_reason")
        qflags = pose.get("quality_flags") or []
        if reason in {"severe_occlusion", "swimmer_outside_frame"} or "severe_occlusion" in qflags:
            for j in range(k):
                if flags[i][j] != "valid":
                    flags[i][j] = "occluded"

    timestamps_s = np.array(
        [_safe_timestamp_s(p) for p in ordered],
        dtype=np.float64,
    )
    nominal_dt = _repair_timestamps(timestamps_s)

    # Outlier removal via velocity / acceleration / continuity
    for j in range(k):
        _mark_outliers_1d(xs[:, j], ys[:, j], timestamps_s, flags, j, params, nominal_dt)

    # Confidence-weighted interpolation for short gaps only (time-based)
    for j in range(k):
        _interpolate_short_gaps(
            xs[:, j], ys[:, j], confs[:, j], timestamps_s, flags, j, params
        )

    # Savitzky–Golay on contiguous valid/interpolated segments (not across occlusions)
    for j in range(k):
        _savgol_segments(xs[:, j], ys[:, j], flags, j, params)

    # Build smoothed pose records (crop-relative coords remapped from full-frame)
    smoothed: list[dict[str, Any]] = []
    frame_confidence: list[dict[str, Any]] = []
    for i, pose in enumerate(ordered):
        crop = pose.get("crop_coordinates")
        if not isinstance(crop, (list, tuple)) or len(crop) < 2:
            crop = [0.0, 0.0, 0.0, 0.0]
        x1, y1 = float(crop[0]), float(crop[1])
        kps_out = []
        valid_count = 0
        for j, name in enumerate(COCO_WHOLEBODY_KEYPOINT_NAMES):
            flag = flags[i][j]
            if np.isnan(xs[i, j]) or np.isnan(ys[i, j]) or flag in {
                "unavailable",
                "occluded",
                "outlier_removed",
                "low_confidence",
            }:
                kps_out.append(
                    {
                        "name": name,
                        "x": None,
                        "y": None,
                        "z": None,
                        "confidence": float(confs[i, j]),
                        "x_crop": None,
                        "y_crop": None,
                        "quality_flag": flag
                        if flag
                        in {
                            "valid",
                            "low_confidence",
                            "interpolated",
                            "outlier_removed",
                            "occluded",
                            "unavailable",
                        }
                        else "unavailable",
                    }
                )
                continue
            ox, oy = float(xs[i, j]), float(ys[i, j])
            if flag == "valid":
                valid_count += 1
            kps_out.append(
                {
                    "name": name,
                    "x": ox,
                    "y": oy,
                    "z": None,
                    "confidence": float(confs[i, j]),
                    "x_crop": ox - x1,
                    "y_crop": oy - y1,
                    "quality_flag": flag,
                }
            )

        core_valid = sum(
            1
            for j in CORE_BODY_INDICES
            if j < k and kps_out[j]["x"] is not None and kps_out[j]["quality_flag"] in {"valid", "interpolated"}
        )
        # Average confidence over core joints that survived as motion samples.
        # Ignore low-confidence / face-hand dilution from WholeBody slots.
        core_conf_vals = [
            float(confs[i, j])
            for j in CORE_BODY_INDICES
            if j < k and flags[i][j] in {"valid", "interpolated"}
        ]
        overall = float(np.mean(core_conf_vals)) if core_conf_vals else 0.0
        usable = (
            core_valid >= params.usable_frame_min_core_joints
            and overall >= params.usable_frame_min_confidence
            and any(kp["quality_flag"] in {"valid", "interpolated"} for kp in kps_out)
        )
        smoothed.append(
            {
                **{key: pose.get(key) for key in (
                    "video_id",
                    "job_id",
                    "frame_number",
                    "timestamp_ms",
                    "swimmer_track_id",
                    "crop_coordinates",
                    "model_name",
                    "model_version",
                    "inference_resolution",
                    "processing_duration_ms",
                )},
                "keypoints": kps_out,
                "overall_pose_confidence": overall,
                "usable": usable,
                "unusable_reason": None if usable else "insufficient_smoothed_keypoints",
                "quality_flags": sorted(
                    {kp["quality_flag"] for kp in kps_out if kp.get("quality_flag")}
                ),
                "dataset": "smoothed",
                "filter_method": _filter_method_name(),
            }
        )
        frame_confidence.append(
            {
                "frame_number": pose.get("frame_number"),
                "timestamp_ms": pose.get("timestamp_ms"),
                "overall_pose_confidence": overall,
                "valid_keypoint_count": valid_count,
                "interpolated_keypoint_count": sum(
                    1 for kp in kps_out if kp["quality_flag"] == "interpolated"
                ),
                "usable": usable,
            }
        )

    coverage = _compute_coverage(ordered, smoothed, tracked_frame_numbers)
    limitations: list[str] = []
    if coverage.longest_missing_interval_frames >= params.long_occlusion_gap_frames:
        limitations.append(
            f"Long occlusion/gap of {coverage.longest_missing_interval_frames} frames left unavailable"
        )

    # Ensure raw is still an exact deep copy of input (identity check via re-copy compare caller-side)
    return SmoothPoseResult(
        raw_poses=raw,
        smoothed_poses=smoothed,
        frame_confidence=frame_confidence,
        coverage=coverage,
        params=params.__dict__.copy(),
        filter_method=_filter_method_name(),
        limitations=limitations,
    )


def _filter_method_name() -> str:
    return (
        "confidence_weighted_short_gap_interpolation+"
        "velocity_acceleration_outlier_rejection+"
        "savgol_on_contiguous_segments"
    )


def _safe_frame_number(pose: dict[str, Any], default: int = 0) -> int:
    value = pose.get("frame_number", default)
    if value is None:
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _safe_timestamp_s(pose: dict[str, Any]) -> float:
    value = pose.get("timestamp_ms")
    if value is None:
        return 0.0
    try:
        return float(value) / 1000.0
    except (TypeError, ValueError):
        return 0.0


def _repair_timestamps(timestamps_s: np.ndarray) -> float:
    """
    Make timestamps strictly increasing.

    Uses the median positive delta from the series when available so 24/60 fps
    (and interval-subsampled) clips are not force-fit to 30 fps.
    Returns the nominal dt used for repairs (seconds).
    """
    n = len(timestamps_s)
    if n == 0:
        return 1.0 / 30.0

    positive_dts = [
        float(timestamps_s[i] - timestamps_s[i - 1])
        for i in range(1, n)
        if timestamps_s[i] > timestamps_s[i - 1]
    ]
    if positive_dts:
        nominal_dt = float(np.median(positive_dts))
    else:
        nominal_dt = 1.0 / 30.0
    nominal_dt = max(nominal_dt, 1e-3)

    for i in range(1, n):
        if timestamps_s[i] <= timestamps_s[i - 1]:
            timestamps_s[i] = timestamps_s[i - 1] + nominal_dt
    return nominal_dt


def _mark_outliers_1d(
    xs: np.ndarray,
    ys: np.ndarray,
    timestamps_s: np.ndarray,
    flags: list[list[QualityFlag]],
    j: int,
    params: SmoothingParams,
    nominal_dt: float = 1.0 / 30.0,
) -> None:
    """Reject impossible jumps using the last valid sample (not only i-1)."""
    n = len(xs)
    last_valid = -1
    prev_valid = -1
    # continuity_max_jump_px is defined per ~native frame; always scale from that
    # reference so subsampled / VFR series are not over-rejected.
    reference_dt = 1.0 / 30.0
    fallback_dt = max(float(nominal_dt), reference_dt, 1e-3)
    for i in range(n):
        if flags[i][j] != "valid" or np.isnan(xs[i]) or np.isnan(ys[i]):
            continue
        if last_valid < 0:
            prev_valid = -1
            last_valid = i
            continue

        dx = xs[i] - xs[last_valid]
        dy = ys[i] - ys[last_valid]
        jump = float(np.hypot(dx, dy))
        dt = float(timestamps_s[i] - timestamps_s[last_valid])
        if dt <= 1e-6:
            dt = fallback_dt
        speed = jump / dt
        max_jump = params.continuity_max_jump_px * max(1.0, dt / reference_dt)
        reject = jump > max_jump or speed > params.max_joint_velocity_px_s

        if not reject and prev_valid >= 0:
            prev_dx = xs[last_valid] - xs[prev_valid]
            prev_dy = ys[last_valid] - ys[prev_valid]
            dt_prev = float(timestamps_s[last_valid] - timestamps_s[prev_valid])
            if dt_prev <= 1e-6:
                dt_prev = fallback_dt
            vx = dx / dt
            vy = dy / dt
            prev_vx = prev_dx / dt_prev
            prev_vy = prev_dy / dt_prev
            dt_acc = 0.5 * (dt + dt_prev)
            if dt_acc <= 1e-6:
                dt_acc = fallback_dt
            accel = float(np.hypot((vx - prev_vx) / dt_acc, (vy - prev_vy) / dt_acc))
            if accel > params.max_joint_acceleration_px_s2:
                reject = True

        if reject:
            xs[i] = np.nan
            ys[i] = np.nan
            flags[i][j] = "outlier_removed"
            continue

        prev_valid = last_valid
        last_valid = i


def _interpolate_short_gaps(
    xs: np.ndarray,
    ys: np.ndarray,
    confs: np.ndarray,
    timestamps_s: np.ndarray,
    flags: list[list[QualityFlag]],
    j: int,
    params: SmoothingParams,
) -> None:
    n = len(xs)
    i = 0
    while i < n:
        if flags[i][j] == "valid" and not np.isnan(xs[i]):
            i += 1
            continue
        # find gap start/end between valid anchors
        start = i
        while i < n and not (flags[i][j] == "valid" and not np.isnan(xs[i])):
            # Do not bridge occluded spans
            if flags[i][j] == "occluded":
                start = -1
                break
            i += 1
        if start < 0:
            i += 1
            continue
        end = i  # first valid after gap, or n
        left = start - 1
        right = end if end < n and flags[end][j] == "valid" and not np.isnan(xs[end]) else -1
        gap = end - start
        if left < 0 or right < 0:
            i = max(i, start + 1)
            continue
        if gap <= 0:
            continue
        if gap > params.max_interpolation_gap_frames:
            # Long occlusion / missing interval — leave unavailable
            for g in range(start, end):
                if flags[g][j] not in {"occluded", "outlier_removed"}:
                    flags[g][j] = "unavailable"
                xs[g] = np.nan
                ys[g] = np.nan
            continue

        # Confidence-weighted linear interpolation between anchors (time-based)
        c0 = max(confs[left], 1e-3)
        c1 = max(confs[right], 1e-3)
        t0 = float(timestamps_s[left])
        t1 = float(timestamps_s[right])
        span = t1 - t0
        for g in range(start, end):
            if span <= 1e-9:
                t = (g - left) / float(right - left)
            else:
                t = (float(timestamps_s[g]) - t0) / span
            t = min(1.0, max(0.0, t))
            # Weight toward higher-confidence anchor
            w1 = t * c1
            w0 = (1.0 - t) * c0
            wsum = w0 + w1
            xs[g] = (w0 * xs[left] + w1 * xs[right]) / wsum
            ys[g] = (w0 * ys[left] + w1 * ys[right]) / wsum
            confs[g] = float((w0 * confs[left] + w1 * confs[right]) / wsum)
            flags[g][j] = "interpolated"


def _savgol_segments(
    xs: np.ndarray,
    ys: np.ndarray,
    flags: list[list[QualityFlag]],
    j: int,
    params: SmoothingParams,
) -> None:
    n = len(xs)
    window = params.savgol_window
    poly = params.savgol_polyorder
    if window < 3 or window % 2 == 0:
        window = max(3, window + (1 - window % 2))
    if poly >= window:
        poly = max(1, window - 2)

    i = 0
    while i < n:
        if flags[i][j] not in {"valid", "interpolated"} or np.isnan(xs[i]):
            i += 1
            continue
        start = i
        while i < n and flags[i][j] in {"valid", "interpolated"} and not np.isnan(xs[i]):
            i += 1
        end = i
        length = end - start
        if length < window:
            continue
        seg_x = xs[start:end].copy()
        seg_y = ys[start:end].copy()
        w = window if length >= window else (length - (1 - length % 2))
        if w < 3:
            continue
        p = min(poly, w - 1)
        xs[start:end] = savgol_filter(seg_x, window_length=w, polyorder=p, mode="interp")
        ys[start:end] = savgol_filter(seg_y, window_length=w, polyorder=p, mode="interp")


def _compute_coverage(
    raw_ordered: list[dict[str, Any]],
    smoothed: list[dict[str, Any]],
    tracked_frame_numbers: set[int] | None,
) -> PoseCoverageStats:
    total = len(smoothed)
    if total == 0:
        return PoseCoverageStats(0, 0, 0, 0, 0, 0, 0, 0, 0)

    usable = sum(1 for p in smoothed if p.get("usable"))
    frames_with_kp = 0
    available = 0
    total_slots = 0
    confs = []
    missing_run = 0
    longest_missing = 0
    for p in smoothed:
        kps = p.get("keypoints") or []
        total_slots += len(kps)
        present = 0
        for kp in kps:
            if kp.get("x") is not None and kp.get("quality_flag") in {"valid", "interpolated"}:
                available += 1
                present += 1
        if present > 0:
            frames_with_kp += 1
            missing_run = 0
        else:
            missing_run += 1
            longest_missing = max(longest_missing, missing_run)
        confs.append(float(p.get("overall_pose_confidence") or 0.0))

    tracked_overlap = 0.0
    if tracked_frame_numbers:
        pose_frames = {
            _safe_frame_number(p, default=-1)
            for p in smoothed
            if p.get("usable")
        }
        if tracked_frame_numbers:
            tracked_overlap = 100.0 * len(pose_frames & tracked_frame_numbers) / len(tracked_frame_numbers)

    return PoseCoverageStats(
        pose_coverage_percentage=100.0 * frames_with_kp / total,
        usable_frame_percentage=100.0 * usable / total,
        keypoint_availability_percentage=(100.0 * available / total_slots) if total_slots else 0.0,
        longest_missing_interval_frames=longest_missing,
        average_pose_confidence=float(np.mean(confs)) if confs else 0.0,
        swimmer_tracking_overlap_percentage=tracked_overlap,
        total_frames=total,
        usable_frames=usable,
        frames_with_any_valid_keypoint=frames_with_kp,
    )

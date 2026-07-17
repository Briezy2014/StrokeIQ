"""Multi-landmark butterfly stroke-cycle detection."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from scipy.signal import find_peaks, savgol_filter

from app.services.butterfly.signals import ButterflySignals
from app.services.butterfly.types import CycleBoundary, StrokeEvent, confidence_label


@dataclass
class CycleDetectorParams:
    min_cycle_duration_s: float = 0.70
    max_cycle_duration_s: float = 2.20
    min_peak_prominence: float = 0.08
    min_bilateral_sync: float = 0.25
    entry_smooth_window: int = 5
    breath_min_prominence: float = 0.04
    breath_min_elevation: float = 0.0


@dataclass
class CycleDetectionResult:
    cycles: list[CycleBoundary]
    events: list[StrokeEvent]
    entry_signal: np.ndarray
    entry_frames: list[int]
    breath_frames: list[int]
    view_suitability: float
    quality_flags: list[str]
    method: str


def _nan_interp(y: np.ndarray) -> np.ndarray:
    y = y.astype(np.float64).copy()
    n = len(y)
    if n == 0:
        return y
    idx = np.arange(n)
    good = np.isfinite(y)
    if good.sum() == 0:
        return np.zeros(n)
    if good.sum() == 1:
        y[:] = y[good][0]
        return y
    y[~good] = np.interp(idx[~good], idx[good], y[good])
    return y


def detect_butterfly_cycles(
    signals: ButterflySignals,
    *,
    params: CycleDetectorParams | None = None,
    view_hint: str = "side",
) -> CycleDetectionResult:
    """
    Detect butterfly cycles using wrists + shoulders + elbows (+ hips/nose).

    Hand entry ≈ synchronized forward-extrema of both wrists, confirmed by
    elbow/shoulder forward support and a forward→backward velocity flip.
    A cycle is entry_i → entry_{i+1}; never defined from one landmark alone.
    """
    params = params or CycleDetectorParams()
    method = (
        "multi_landmark_entry_peaks:"
        "wrist_forward+bilateral_sync+elbow_shoulder_support+velocity_flip"
    )
    flags: list[str] = []

    view_suitability = {
        "side": 1.0,
        "diagonal_side": 0.7,
        "deck": 0.35,
        "end": 0.2,
        "underwater_side": 0.1,
        "underwater_front": 0.1,
        "mixed": 0.5,
        "unknown": 0.55,
    }.get(view_hint, 0.55)
    if view_hint in {"end", "underwater_front"}:
        flags.append("view_poor_for_surface_butterfly")

    n = len(signals.timestamps_s)
    if n < 5:
        flags.append("insufficient_frames")
        return CycleDetectionResult([], [], np.asarray([]), [], [], view_suitability, flags, method)

    wrist = _nan_interp(signals.wrist_forward)
    elbow = _nan_interp(signals.elbow_forward)
    shoulder = _nan_interp(signals.shoulder_forward)
    hip = _nan_interp(signals.hip_forward)
    sync = _nan_interp(signals.bilateral_sync)
    # Normalize each channel to 0..1 for a composite entry score
    def norm01(x: np.ndarray) -> np.ndarray:
        lo, hi = np.nanmin(x), np.nanmax(x)
        if hi - lo < 1e-6:
            return np.zeros_like(x)
        return (x - lo) / (hi - lo)

    composite = (
        0.45 * norm01(wrist)
        + 0.20 * norm01(elbow)
        + 0.15 * norm01(shoulder)
        + 0.10 * norm01(hip)
        + 0.10 * sync
    )
    win = params.entry_smooth_window
    if win >= 3 and n >= win:
        if win % 2 == 0:
            win += 1
        composite = savgol_filter(composite, window_length=min(win, n - (1 - n % 2)), polyorder=2, mode="interp")

    # Velocity of wrist_forward for flip confirmation
    dt = np.diff(signals.timestamps_s, prepend=signals.timestamps_s[0])
    dt[dt <= 1e-6] = np.median(dt[dt > 1e-6]) if np.any(dt > 1e-6) else (1 / 30)
    vel = np.gradient(wrist, signals.timestamps_s)

    # Minimum peak distance from min cycle duration
    med_dt = float(np.median(dt))
    min_dist = max(2, int(params.min_cycle_duration_s / max(med_dt, 1e-3)))
    peaks, _props = find_peaks(
        composite,
        distance=min_dist,
        prominence=params.min_peak_prominence,
    )
    peak_list = peaks.tolist()

    # find_peaks ignores array endpoints; butterfly entries often land on clip edges.
    hi = float(np.percentile(composite, 65))
    if composite[0] >= hi and (len(peak_list) == 0 or peak_list[0] >= min_dist):
        peak_list = [0] + peak_list
    if composite[-1] >= hi and (len(peak_list) == 0 or (n - 1 - peak_list[-1]) >= min_dist):
        peak_list = peak_list + [n - 1]

    entry_idxs: list[int] = []
    for p in peak_list:
        # Require bilateral support and multi-landmark confirmation
        sync_ok = sync[p] >= params.min_bilateral_sync or (
            np.isfinite(signals.left_wrist_forward[p]) and np.isfinite(signals.right_wrist_forward[p])
        )
        landmark_support = sum(
            [
                np.isfinite(signals.wrist_forward[p]),
                np.isfinite(signals.elbow_forward[p]),
                np.isfinite(signals.shoulder_forward[p]),
                np.isfinite(signals.hip_forward[p]),
            ]
        )
        # Velocity should be near zero or flipping from +fwd to -fwd around entry
        i0 = max(0, p - 2)
        i1 = min(n - 1, p + 2)
        vel_std = float(np.nanstd(vel)) if np.any(np.isfinite(vel)) else 1.0
        vel_flip = (
            bool(np.any(vel[i0:p] >= 0) and np.any(vel[p : i1 + 1] <= 0))
            or abs(float(vel[p])) < vel_std * 0.75
            or p in {0, n - 1}
        )
        if sync_ok and landmark_support >= 2 and vel_flip:
            entry_idxs.append(p)
        else:
            flags.append(f"rejected_peak_frame_{int(signals.frame_numbers[p])}")

    # De-duplicate near-duplicates
    if entry_idxs:
        kept = [entry_idxs[0]]
        for p in entry_idxs[1:]:
            if p - kept[-1] >= max(2, min_dist // 2):
                kept.append(p)
        entry_idxs = kept

    # Breath estimates from head elevation peaks (nose above shoulders)
    elev = _nan_interp(signals.head_elevation)
    breath_peaks, _ = find_peaks(
        elev,
        distance=min_dist,
        prominence=params.breath_min_prominence,
    )
    breath_idxs = [int(b) for b in breath_peaks.tolist() if elev[b] >= params.breath_min_elevation]

    cycles: list[CycleBoundary] = []
    events: list[StrokeEvent] = []

    for i, eidx in enumerate(entry_idxs):
        conf = _entry_confidence(signals, eidx, view_suitability)
        events.append(
            StrokeEvent(
                event_type="hand_entry",
                timestamp_ms=float(signals.timestamps_ms[eidx]),
                frame_number=int(signals.frame_numbers[eidx]),
                confidence=conf,
                confidence_label=confidence_label(conf),
                side="both",
                cycle_index=i if i < len(entry_idxs) - 1 else None,
                quality_flags=_local_flags(signals, eidx),
            )
        )

    for ci in range(len(entry_idxs) - 1):
        a, b = entry_idxs[ci], entry_idxs[ci + 1]
        dur = float(signals.timestamps_s[b] - signals.timestamps_s[a])
        if dur < params.min_cycle_duration_s * 0.85 or dur > params.max_cycle_duration_s * 1.15:
            flags.append(f"cycle_{ci}_duration_out_of_range")
            # Still record but mark incomplete/low quality
            complete = False
        else:
            complete = True

        pull = _find_pull_initiation(vel, a, b)
        recovery = _find_recovery(vel, a, b, pull)
        left_e = _side_entry(signals.left_wrist_forward, a, b)
        right_e = _side_entry(signals.right_wrist_forward, a, b)
        cconf = float(
            np.mean(
                [
                    _entry_confidence(signals, a, view_suitability),
                    _entry_confidence(signals, b, view_suitability),
                    float(np.nanmean(signals.pose_confidence[a : b + 1])),
                ]
            )
        )
        qflags = sorted(set(_local_flags(signals, a) + _local_flags(signals, b)))
        if not complete:
            qflags.append("duration_outlier")

        cycle = CycleBoundary(
            cycle_index=ci,
            start_frame=int(signals.frame_numbers[a]),
            end_frame=int(signals.frame_numbers[b]),
            start_ms=float(signals.timestamps_ms[a]),
            end_ms=float(signals.timestamps_ms[b]),
            duration_s=dur,
            entry_frame=int(signals.frame_numbers[a]),
            next_entry_frame=int(signals.frame_numbers[b]),
            pull_initiation_frame=int(signals.frame_numbers[pull]) if pull is not None else None,
            recovery_frame=int(signals.frame_numbers[recovery]) if recovery is not None else None,
            left_entry_frame=int(signals.frame_numbers[left_e]) if left_e is not None else None,
            right_entry_frame=int(signals.frame_numbers[right_e]) if right_e is not None else None,
            complete=complete,
            confidence=cconf,
            quality_flags=qflags,
        )
        cycles.append(cycle)
        events.append(
            StrokeEvent(
                event_type="cycle_start",
                timestamp_ms=cycle.start_ms,
                frame_number=cycle.start_frame,
                confidence=cconf,
                confidence_label=confidence_label(cconf),
                side="both",
                cycle_index=ci,
                quality_flags=qflags,
            )
        )
        events.append(
            StrokeEvent(
                event_type="cycle_end",
                timestamp_ms=cycle.end_ms,
                frame_number=cycle.end_frame,
                confidence=cconf,
                confidence_label=confidence_label(cconf),
                side="both",
                cycle_index=ci,
                quality_flags=qflags,
            )
        )

    for bi in breath_idxs:
        # Associate breath with enclosing cycle if any
        cyc_i = None
        for c in cycles:
            if c.start_frame <= int(signals.frame_numbers[bi]) <= c.end_frame:
                cyc_i = c.cycle_index
                break
        bconf = float(
            0.4 * signals.head_visible[bi]
            + 0.3 * signals.shoulder_visible[bi]
            + 0.3 * min(1.0, signals.pose_confidence[bi] + 0.2)
        ) * view_suitability
        events.append(
            StrokeEvent(
                event_type="breath_estimate",
                timestamp_ms=float(signals.timestamps_ms[bi]),
                frame_number=int(signals.frame_numbers[bi]),
                confidence=bconf,
                confidence_label=confidence_label(bconf),
                side=None,
                cycle_index=cyc_i,
                quality_flags=_local_flags(signals, bi) + ["breath_from_head_elevation"],
                notes="estimated from nose elevation above shoulder line",
            )
        )

    if len(cycles) < 2:
        flags.append("fewer_than_two_complete_cycles")

    return CycleDetectionResult(
        cycles=cycles,
        events=events,
        entry_signal=composite,
        entry_frames=[int(signals.frame_numbers[i]) for i in entry_idxs],
        breath_frames=[int(signals.frame_numbers[i]) for i in breath_idxs],
        view_suitability=view_suitability,
        quality_flags=sorted(set(flags)),
        method=method,
    )


def _entry_confidence(signals: ButterflySignals, idx: int, view_suitability: float) -> float:
    parts = [
        float(signals.wrist_visible[idx]),
        float(signals.shoulder_visible[idx]),
        float(signals.head_visible[idx]) * 0.5 + 0.5,  # head optional
        float(np.clip(signals.bilateral_sync[idx], 0, 1)),
        float(np.clip(signals.pose_confidence[idx], 0, 1)),
        float(np.clip(signals.track_confidence[idx], 0, 1)),
        float(view_suitability),
    ]
    return float(np.clip(np.mean(parts), 0, 1))


def _local_flags(signals: ButterflySignals, idx: int) -> list[str]:
    flags = []
    if signals.wrist_visible[idx] < 0.5:
        flags.append("wrist_low_visibility")
    if signals.shoulder_visible[idx] < 0.5:
        flags.append("shoulder_low_visibility")
    if signals.head_visible[idx] < 0.5:
        flags.append("head_low_visibility")
    if signals.bilateral_sync[idx] < 0.3:
        flags.append("bilateral_asynchrony")
    return flags


def _find_pull_initiation(vel: np.ndarray, a: int, b: int) -> int | None:
    """First sustained negative forward-velocity after entry."""
    if b - a < 3:
        return None
    seg = vel[a + 1 : b]
    neg = np.where(seg < 0)[0]
    if neg.size == 0:
        return None
    return int(a + 1 + neg[0])


def _find_recovery(vel: np.ndarray, a: int, b: int, pull: int | None) -> int | None:
    """Forward-velocity return after pull (recovery start proxy)."""
    start = (pull or a) + 1
    if b - start < 2:
        return None
    seg = vel[start:b]
    pos = np.where(seg > 0)[0]
    if pos.size == 0:
        return None
    return int(start + pos[0])


def _side_entry(side_fwd: np.ndarray, a: int, b: int) -> int | None:
    """Peak forward position for one wrist near cycle start (entry proxy)."""
    lo = max(0, a - 2)
    hi = min(len(side_fwd) - 1, a + max(2, (b - a) // 4))
    seg = side_fwd[lo : hi + 1]
    if not np.any(np.isfinite(seg)):
        return None
    return int(lo + np.nanargmax(seg))

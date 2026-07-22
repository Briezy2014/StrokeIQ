"""Underwater phase, dolphin-kick, and breakout detection (no Gemini)."""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np
from scipy.signal import find_peaks, savgol_filter

from app.services.underwater.signals import UnderwaterSignals
from app.services.underwater.types import (
    UnderwaterEvent,
    UnderwaterPhase,
    confidence_label,
)


@dataclass
class UnderwaterDetectorParams:
    min_kick_interval_s: float = 0.28
    max_kick_interval_s: float = 1.10
    kick_prominence_px: float = 4.0
    kick_prominence_frac_std: float = 0.35
    underwater_wrist_activity_percentile: float = 45.0
    min_underwater_duration_s: float = 0.40
    smooth_window: int = 5


@dataclass
class UnderwaterDetectionResult:
    phase: UnderwaterPhase | None
    events: list[UnderwaterEvent]
    kick_frames: list[int]
    kick_indices: list[int]
    water_entry_frame: int | None
    underwater_start_frame: int | None
    breakout_frame: int | None
    first_surface_stroke_frame: int | None
    underwater_end_frame: int | None
    ankle_kick_signal: np.ndarray
    quality_flags: list[str] = field(default_factory=list)
    method: str = (
        "ankle_oscillation+hip_knee+wrist_activity+bbox+splash+surface_stroke_gate"
    )
    view_mode: str = "unknown"


def _interp(y: np.ndarray) -> np.ndarray:
    y = y.astype(np.float64).copy()
    n = len(y)
    if n == 0:
        return y
    good = np.isfinite(y)
    if good.sum() == 0:
        return np.zeros(n)
    if good.sum() == 1:
        y[:] = y[good][0]
        return y
    idx = np.arange(n)
    y[~good] = np.interp(idx[~good], idx[good], y[good])
    return y


def _norm01(x: np.ndarray) -> np.ndarray:
    x = np.asarray(x, dtype=np.float64)
    lo, hi = np.nanmin(x), np.nanmax(x)
    if not np.isfinite(lo) or hi - lo < 1e-9:
        return np.zeros_like(x)
    return (x - lo) / (hi - lo)


def detect_underwater_phase(
    signals: UnderwaterSignals,
    *,
    params: UnderwaterDetectorParams | None = None,
    view_hint: str = "side",
    surface_stroke_entry_frames: list[int] | None = None,
) -> UnderwaterDetectionResult:
    """
    Detect underwater phase, dolphin kicks, and breakout from multi-signal cues.

    Kick proxy: ankle vertical peaks confirmed by knee/hip motion.
    Breakout: first surface-stroke entry and/or wrist-activity rise with depth drop.
    """
    params = params or UnderwaterDetectorParams()
    flags: list[str] = []
    n = len(signals.timestamps_s)
    empty = UnderwaterDetectionResult(
        phase=None,
        events=[],
        kick_frames=[],
        kick_indices=[],
        water_entry_frame=None,
        underwater_start_frame=None,
        breakout_frame=None,
        first_surface_stroke_frame=None,
        underwater_end_frame=None,
        ankle_kick_signal=np.asarray([]),
        quality_flags=flags,
        view_mode=view_hint,
    )
    if n < 3:
        flags.append("short_clip")
        empty.quality_flags = flags
        return empty

    underwater_view = view_hint.startswith("underwater")
    deck_view = view_hint in {"deck", "end"}
    if deck_view:
        flags.append("deck_view_challenging_for_underwater")
    if underwater_view:
        flags.append("underwater_camera_view")

    ankle = _interp(signals.ankle_y)
    knee = _interp(signals.knee_y)
    hip = _interp(signals.hip_y)
    win = params.smooth_window
    if win >= 3 and n >= win:
        if win % 2 == 0:
            win += 1
        w = min(win, n - (1 - n % 2))
        if w >= 3:
            ankle = savgol_filter(ankle, w, 2, mode="interp")
            knee = savgol_filter(knee, w, 2, mode="interp")
            hip = savgol_filter(hip, w, 2, mode="interp")

    # Kick visualization signal: high-pass-ish ankle motion magnitude
    if n >= 7:
        bw = min(11, n if n % 2 == 1 else n - 1)
        baseline = savgol_filter(ankle, bw, 2, mode="interp")
        kick_energy = np.abs(ankle - baseline)
    else:
        kick_energy = np.abs(np.gradient(ankle))

    wrist_act_raw = _interp(signals.wrist_activity)
    wrist_act = _norm01(wrist_act_raw)
    depth = _norm01(_interp(signals.body_depth_proxy))
    splash = signals.splash_cue

    # Oscillation strength: prefer ankles; fall back to hip when feet are missing.
    osc_source = ankle.copy()
    if float(np.mean(signals.ankle_visible)) < 0.45:
        osc_source = hip.copy()
        flags.append("oscillation_from_hip_due_to_low_ankle_visibility")
    osc = np.zeros(n)
    half = max(2, int(0.35 / max(float(np.median(np.diff(signals.timestamps_s))), 1e-3)))
    for i in range(n):
        lo, hi = max(0, i - half), min(n, i + half + 1)
        osc[i] = float(np.std(osc_source[lo:hi]))
    osc_n = _norm01(osc)

    # Low wrist activity is streamlining — use a robust low-activity score so a
    # later surface segment does not erase the underwater window.
    wrist_low = 1.0 - wrist_act
    uw_score = (
        0.22 * depth
        + 0.33 * wrist_low
        + 0.35 * osc_n
        + 0.10 * signals.hip_visible
    )
    if underwater_view:
        uw_score = np.clip(uw_score + 0.12, 0, 1)
    if deck_view:
        uw_score *= 0.75

    # Surface-only clips: oscillation never rises and wrists stay active.
    if float(np.max(osc_n)) < 0.35 and float(np.mean(wrist_act)) > 0.55 and not underwater_view:
        flags.append("surface_dominant_motion")
        uw_score *= 0.4

    thr = max(0.40, float(np.nanpercentile(uw_score, 55)) * 0.90)
    uw_mask = uw_score >= thr
    start_i, end_i = _longest_true_run(uw_mask)

    surface_entries = list(surface_stroke_entry_frames or [])
    first_stroke_i = None
    first_stroke_frame = None

    # Duration gate
    if start_i is not None and end_i is not None:
        dur = float(signals.timestamps_s[end_i] - signals.timestamps_s[start_i])
        if dur < params.min_underwater_duration_s:
            flags.append("underwater_phase_too_short")
            start_i, end_i = None, None

    if start_i is None or end_i is None:
        flags.append("no_valid_underwater_phase")
        if surface_entries and float(np.mean(wrist_act)) > 0.5:
            flags.append("clip_begins_after_breakout")
        empty.quality_flags = sorted(set(flags))
        empty.ankle_kick_signal = kick_energy
        if surface_entries:
            empty.first_surface_stroke_frame = surface_entries[0]
        return empty

    # Water entry
    water_entry_i = None
    if start_i > 0 and not uw_mask[0]:
        search_lo = max(0, start_i - max(3, half))
        seg = splash[search_lo : start_i + 1]
        if seg.size and float(np.max(seg)) >= 0.5:
            water_entry_i = search_lo + int(np.argmax(seg))
        else:
            water_entry_i = start_i
            flags.append("no_visible_water_entry")
    elif uw_mask[0] or start_i == 0:
        flags.append("already_underwater_at_clip_start")
        water_entry_i = None

    # First surface stroke after underwater start
    for fr in sorted(surface_entries):
        idxs = np.where(signals.frame_numbers == fr)[0]
        if idxs.size == 0:
            continue
        ii = int(idxs[0])
        if ii >= start_i:
            first_stroke_i = ii
            first_stroke_frame = fr
            break

    # Breakout
    breakout_i = None
    if first_stroke_i is not None:
        breakout_i = first_stroke_i
    else:
        mid = start_i + max(1, (end_i - start_i) // 3)
        wrist_thr = float(np.nanpercentile(wrist_act[mid:], 70)) if mid < n else 0.6
        depth_med = float(np.nanmedian(depth[start_i : end_i + 1]))
        for i in range(mid, n):
            if wrist_act[i] >= max(0.55, wrist_thr) and depth[i] <= depth_med:
                breakout_i = i
                break
        if breakout_i is None:
            breakout_i = end_i
            flags.append("breakout_estimated_from_underwater_end")

    kick_end = breakout_i if breakout_i is not None else end_i
    kick_end = max(start_i + 2, min(kick_end, n))
    med_dt = float(np.median(np.diff(signals.timestamps_s))) if n > 1 else 1 / 30
    min_dist = max(2, int(params.min_kick_interval_s / max(med_dt, 1e-3)))

    # Peaks on ankle_y (and valleys) — one kick beat per extremum period
    seg = ankle[start_i:kick_end]
    seg_std = float(np.std(seg)) if seg.size else 0.0
    prom = max(params.kick_prominence_px, params.kick_prominence_frac_std * seg_std)
    peaks_rel, _ = find_peaks(seg, distance=min_dist, prominence=prom)
    valleys_rel, _ = find_peaks(-seg, distance=min_dist, prominence=prom)
    # Prefer the polarity with more detections; if similar, use peaks
    if valleys_rel.size > peaks_rel.size + 1:
        chosen = valleys_rel
    else:
        chosen = peaks_rel
    kick_idxs = [start_i + int(p) for p in chosen.tolist()]

    # Confirm with knee/hip support when ankles weak
    confirmed = []
    for ki in kick_idxs:
        ankle_ok = signals.ankle_visible[ki] >= 0.25
        hip_ok = signals.hip_visible[ki] >= 0.5
        knee_delta = abs(knee[ki] - float(np.mean(knee[max(0, ki - 2) : ki + 3])))
        if ankle_ok or (hip_ok and knee_delta >= 0.5 * prom):
            confirmed.append(ki)
        else:
            flags.append(f"kick_rejected_low_visibility_frame_{int(signals.frame_numbers[ki])}")
    kick_idxs = confirmed

    # Feet obscured: fall back to hip/knee oscillation peaks
    if float(np.mean(signals.feet_obscured[start_i:kick_end])) > 0.6:
        flags.append("feet_obscured")
        if len(kick_idxs) < 2:
            hip_seg = hip[start_i:kick_end]
            hprom = max(2.0, 0.3 * float(np.std(hip_seg)))
            hp, _ = find_peaks(hip_seg, distance=min_dist, prominence=hprom)
            kick_idxs = [start_i + int(p) for p in hp.tolist()]
            flags.append("kicks_from_hip_proxy_due_to_obscured_feet")

    if float(np.mean(splash[start_i:kick_end])) > 0.3:
        flags.append("bubbles_or_splash")
    if float(np.nanpercentile(signals.bbox_speed, 90)) > 5 * max(float(np.nanmedian(signals.bbox_speed)), 1e-3):
        flags.append("camera_or_bbox_motion_high")

    dur = float(signals.timestamps_s[end_i] - signals.timestamps_s[start_i])
    phase_conf = float(
        np.clip(
            np.mean(
                [
                    float(np.mean(uw_score[start_i : end_i + 1])),
                    float(np.mean(signals.pose_confidence[start_i : end_i + 1])),
                    float(np.mean(signals.hip_visible[start_i : end_i + 1])),
                    0.75 if kick_idxs else 0.4,
                    0.8 if breakout_i is not None else 0.4,
                ]
            ),
            0,
            1,
        )
    )
    phase = UnderwaterPhase(
        start_frame=int(signals.frame_numbers[start_i]),
        end_frame=int(signals.frame_numbers[end_i]),
        start_ms=float(signals.timestamps_ms[start_i]),
        end_ms=float(signals.timestamps_ms[end_i]),
        duration_s=dur,
        complete=breakout_i is not None,
        confidence=phase_conf,
        quality_flags=sorted(set(flags)),
    )

    events: list[UnderwaterEvent] = []
    if water_entry_i is not None:
        events.append(
            _event(
                "water_entry",
                signals,
                water_entry_i,
                method="splash_cue_or_underwater_transition",
                landmarks=["splash_cue", "body_depth_proxy"],
                conf=0.6 if splash[water_entry_i] >= 0.5 else 0.35,
                qflags=["estimated"] if splash[water_entry_i] < 0.5 else [],
            )
        )
    events.append(
        _event(
            "underwater_start",
            signals,
            start_i,
            method="underwater_likelihood_run_start",
            landmarks=["hip", "ankle", "wrist_activity", "bbox"],
            conf=phase_conf,
        )
    )
    for ki in kick_idxs:
        kconf = float(
            np.clip(
                0.45 * max(signals.ankle_visible[ki], 0.3 if "hip_proxy" in "".join(flags) else 0.0)
                + 0.25 * signals.hip_visible[ki]
                + 0.30 * min(1.0, osc_n[ki] + 0.2),
                0,
                1,
            )
        )
        events.append(
            _event(
                "dolphin_kick",
                signals,
                ki,
                method="ankle_vertical_peak+knee_hip_support",
                landmarks=["left_ankle", "right_ankle", "left_knee", "right_knee", "left_hip", "right_hip"],
                conf=kconf,
                qflags=["feet_obscured"] if signals.feet_obscured[ki] > 0.5 else [],
            )
        )

    if breakout_i is not None:
        bconf = float(
            np.clip(
                0.35 * wrist_act[breakout_i]
                + 0.30 * (1.0 if first_stroke_i == breakout_i else 0.45)
                + 0.20 * signals.pose_confidence[breakout_i]
                + 0.15 * (1.0 - depth[breakout_i]),
                0,
                1,
            )
        )
        events.append(
            _event(
                "breakout",
                signals,
                breakout_i,
                method="wrist_activity_rise+depth_drop+surface_stroke_gate",
                landmarks=["left_wrist", "right_wrist", "left_hip", "right_hip"],
                conf=bconf,
            )
        )
    if first_stroke_i is not None:
        events.append(
            _event(
                "first_surface_stroke",
                signals,
                first_stroke_i,
                method="first_validated_butterfly_cycle_entry_after_underwater",
                landmarks=["left_wrist", "right_wrist", "left_shoulder", "right_shoulder"],
                conf=0.85,
            )
        )
    end_idx = end_i if breakout_i is None else max(end_i, breakout_i)
    end_idx = min(end_idx, n - 1)
    events.append(
        _event(
            "underwater_end",
            signals,
            end_idx,
            method="underwater_likelihood_run_end_or_breakout",
            landmarks=["hip", "wrist_activity"],
            conf=phase_conf * 0.9,
        )
    )

    return UnderwaterDetectionResult(
        phase=phase,
        events=events,
        kick_frames=[int(signals.frame_numbers[i]) for i in kick_idxs],
        kick_indices=kick_idxs,
        water_entry_frame=int(signals.frame_numbers[water_entry_i]) if water_entry_i is not None else None,
        underwater_start_frame=int(signals.frame_numbers[start_i]),
        breakout_frame=int(signals.frame_numbers[breakout_i]) if breakout_i is not None else None,
        first_surface_stroke_frame=first_stroke_frame,
        underwater_end_frame=int(signals.frame_numbers[end_i]),
        ankle_kick_signal=kick_energy,
        quality_flags=sorted(set(flags)),
        view_mode=view_hint,
    )


def _longest_true_run(mask: np.ndarray) -> tuple[int | None, int | None]:
    best = (None, None)
    best_len = 0
    i = 0
    n = len(mask)
    while i < n:
        if not mask[i]:
            i += 1
            continue
        j = i
        while j < n and mask[j]:
            j += 1
        if j - i > best_len:
            best_len = j - i
            best = (i, j - 1)
        i = j
    return best


def _event(
    etype: str,
    signals: UnderwaterSignals,
    idx: int,
    *,
    method: str,
    landmarks: list[str],
    conf: float,
    qflags: list[str] | None = None,
) -> UnderwaterEvent:
    return UnderwaterEvent(
        event_type=etype,  # type: ignore[arg-type]
        timestamp_ms=float(signals.timestamps_ms[idx]),
        frame_number=int(signals.frame_numbers[idx]),
        confidence=float(np.clip(conf, 0, 1)),
        confidence_label=confidence_label(conf),
        method=method,
        supporting_landmarks=landmarks,
        quality_flags=qflags or [],
    )

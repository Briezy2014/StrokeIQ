"""Temporal signal extraction from Milestone 4 smoothed poses."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np

from app.domain.landmarks import COCO_WHOLEBODY_KEYPOINT_NAMES

_VALID = {"valid", "interpolated"}

IDX = {name: i for i, name in enumerate(COCO_WHOLEBODY_KEYPOINT_NAMES)}


@dataclass
class ButterflySignals:
    frame_numbers: np.ndarray
    timestamps_ms: np.ndarray
    timestamps_s: np.ndarray
    # Midpoints / projections
    swim_direction: float  # +1 swim increasing x, -1 decreasing x
    wrist_forward: np.ndarray
    left_wrist_forward: np.ndarray
    right_wrist_forward: np.ndarray
    elbow_forward: np.ndarray
    shoulder_forward: np.ndarray
    hip_forward: np.ndarray
    nose_forward: np.ndarray
    wrist_y: np.ndarray
    left_wrist_y: np.ndarray
    right_wrist_y: np.ndarray
    shoulder_y: np.ndarray
    hip_y: np.ndarray
    nose_y: np.ndarray
    shoulder_width: np.ndarray
    entry_width: np.ndarray  # |lw_x - rw_x| proxy
    bilateral_sync: np.ndarray
    head_elevation: np.ndarray  # shoulder_y - nose_y (image y down: positive => head above)
    pose_confidence: np.ndarray
    wrist_visible: np.ndarray
    shoulder_visible: np.ndarray
    head_visible: np.ndarray
    track_confidence: np.ndarray


def _kp_xy(pose: dict[str, Any], name: str) -> tuple[float, float, float, str]:
    kps = pose.get("keypoints") or []
    idx = IDX[name]
    if idx >= len(kps) or not isinstance(kps[idx], dict):
        return np.nan, np.nan, 0.0, "unavailable"
    kp = kps[idx]
    q = str(kp.get("quality_flag") or ("valid" if kp.get("x") is not None else "unavailable"))
    conf = float(kp.get("confidence") or 0.0)
    x, y = kp.get("x"), kp.get("y")
    if x is None or y is None or q not in _VALID:
        return np.nan, np.nan, conf, q
    return float(x), float(y), conf, q


def extract_butterfly_signals(smoothed_poses: list[dict[str, Any]]) -> ButterflySignals:
    if not smoothed_poses:
        empty = np.asarray([], dtype=np.float64)
        return ButterflySignals(
            frame_numbers=np.asarray([], dtype=np.int32),
            timestamps_ms=empty,
            timestamps_s=empty,
            swim_direction=1.0,
            wrist_forward=empty,
            left_wrist_forward=empty,
            right_wrist_forward=empty,
            elbow_forward=empty,
            shoulder_forward=empty,
            hip_forward=empty,
            nose_forward=empty,
            wrist_y=empty,
            left_wrist_y=empty,
            right_wrist_y=empty,
            shoulder_y=empty,
            hip_y=empty,
            nose_y=empty,
            shoulder_width=empty,
            entry_width=empty,
            bilateral_sync=empty,
            head_elevation=empty,
            pose_confidence=empty,
            wrist_visible=empty,
            shoulder_visible=empty,
            head_visible=empty,
            track_confidence=empty,
        )

    ordered = sorted(smoothed_poses, key=lambda p: (float(p.get("timestamp_ms") or 0), int(p.get("frame_number") or 0)))
    n = len(ordered)
    frames = np.zeros(n, dtype=np.int32)
    ts_ms = np.zeros(n, dtype=np.float64)
    pose_conf = np.zeros(n, dtype=np.float64)
    track_conf = np.ones(n, dtype=np.float64)

    lx = np.full(n, np.nan)
    ly = np.full(n, np.nan)
    rx = np.full(n, np.nan)
    ry = np.full(n, np.nan)
    lex = np.full(n, np.nan)
    rex = np.full(n, np.nan)
    lsx = np.full(n, np.nan)
    lsy = np.full(n, np.nan)
    rsx = np.full(n, np.nan)
    rsy = np.full(n, np.nan)
    lhx = np.full(n, np.nan)
    rhx = np.full(n, np.nan)
    lhy = np.full(n, np.nan)
    rhy = np.full(n, np.nan)
    nx = np.full(n, np.nan)
    ny = np.full(n, np.nan)
    wv = np.zeros(n)
    sv = np.zeros(n)
    hv = np.zeros(n)

    for i, pose in enumerate(ordered):
        frames[i] = int(pose.get("frame_number") or i)
        ts_ms[i] = float(pose.get("timestamp_ms") or 0.0)
        pose_conf[i] = float(pose.get("overall_pose_confidence") or 0.0)
        # Track confidence proxy from usable flag / quality
        if pose.get("usable"):
            track_conf[i] = 1.0
        elif "severe_occlusion" in (pose.get("quality_flags") or []):
            track_conf[i] = 0.3
        else:
            track_conf[i] = 0.6

        lx[i], ly[i], _, lq = _kp_xy(pose, "left_wrist")
        rx[i], ry[i], _, rq = _kp_xy(pose, "right_wrist")
        lex[i], _, _, _ = _kp_xy(pose, "left_elbow")
        rex[i], _, _, _ = _kp_xy(pose, "right_elbow")
        lsx[i], lsy[i], _, lsq = _kp_xy(pose, "left_shoulder")
        rsx[i], rsy[i], _, rsq = _kp_xy(pose, "right_shoulder")
        lhx[i], lhy[i], _, _ = _kp_xy(pose, "left_hip")
        rhx[i], rhy[i], _, _ = _kp_xy(pose, "right_hip")
        nx[i], ny[i], _, nq = _kp_xy(pose, "nose")

        wv[i] = float(lq in _VALID) + float(rq in _VALID)
        sv[i] = float(lsq in _VALID) + float(rsq in _VALID)
        hv[i] = float(nq in _VALID)

    # Swim direction from mid-hip (fallback mid-shoulder) trajectory
    mid_hip_x = np.nanmean(np.vstack([lhx, rhx]), axis=0)
    mid_sh_x = np.nanmean(np.vstack([lsx, rsx]), axis=0)
    trail = mid_hip_x.copy()
    missing = np.isnan(trail)
    trail[missing] = mid_sh_x[missing]
    valid_trail = trail[~np.isnan(trail)]
    if valid_trail.size >= 2:
        swim_direction = 1.0 if (valid_trail[-1] - valid_trail[0]) >= 0 else -1.0
    else:
        swim_direction = 1.0

    def fwd(x: np.ndarray) -> np.ndarray:
        return x * swim_direction

    left_wf = fwd(lx)
    right_wf = fwd(rx)

    def _nanmean2(a: np.ndarray, b: np.ndarray) -> np.ndarray:
        # Prefer available side; average when both present; never invent from empty.
        return np.where(np.isnan(a), b, np.where(np.isnan(b), a, 0.5 * (a + b)))

    wrist_f = _nanmean2(left_wf, right_wf)
    elbow_f = _nanmean2(fwd(lex), fwd(rex))
    shoulder_f = _nanmean2(fwd(lsx), fwd(rsx))
    hip_f = _nanmean2(fwd(lhx), fwd(rhx))
    nose_f = fwd(nx)

    wrist_y = _nanmean2(ly, ry)
    shoulder_y = _nanmean2(lsy, rsy)
    hip_y = _nanmean2(lhy, rhy)

    shoulder_width = np.abs(lsx - rsx)
    entry_width = np.abs(lx - rx)
    # Bilateral sync: 1 when wrists aligned on forward axis relative to shoulder width
    sync_denom = np.where(shoulder_width > 1e-3, shoulder_width, np.nan)
    sync_err = np.abs(left_wf - right_wf) / sync_denom
    bilateral_sync = np.clip(1.0 - sync_err, 0.0, 1.0)

    # Image y increases downward → head above shoulders when nose_y < shoulder_y
    head_elevation = shoulder_y - ny

    return ButterflySignals(
        frame_numbers=frames,
        timestamps_ms=ts_ms,
        timestamps_s=ts_ms / 1000.0,
        swim_direction=swim_direction,
        wrist_forward=wrist_f,
        left_wrist_forward=left_wf,
        right_wrist_forward=right_wf,
        elbow_forward=elbow_f,
        shoulder_forward=shoulder_f,
        hip_forward=hip_f,
        nose_forward=nose_f,
        wrist_y=wrist_y,
        left_wrist_y=ly,
        right_wrist_y=ry,
        shoulder_y=shoulder_y,
        hip_y=hip_y,
        nose_y=ny,
        shoulder_width=shoulder_width,
        entry_width=entry_width,
        bilateral_sync=bilateral_sync,
        head_elevation=head_elevation,
        pose_confidence=pose_conf,
        wrist_visible=wv / 2.0,
        shoulder_visible=sv / 2.0,
        head_visible=hv,
        track_confidence=track_conf,
    )

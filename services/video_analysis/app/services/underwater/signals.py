"""Multi-signal extraction for underwater / breakout analysis."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np

from app.domain.landmarks import COCO_WHOLEBODY_KEYPOINT_NAMES
from app.services.butterfly.signals import _kp_xy

IDX = {name: i for i, name in enumerate(COCO_WHOLEBODY_KEYPOINT_NAMES)}


@dataclass
class UnderwaterSignals:
    frame_numbers: np.ndarray
    timestamps_ms: np.ndarray
    timestamps_s: np.ndarray
    ankle_y: np.ndarray
    left_ankle_y: np.ndarray
    right_ankle_y: np.ndarray
    knee_y: np.ndarray
    hip_y: np.ndarray
    hip_x: np.ndarray
    shoulder_y: np.ndarray
    wrist_y: np.ndarray
    wrist_activity: np.ndarray  # |d(wrist_forward-ish x)| proxy
    body_depth_proxy: np.ndarray  # higher => deeper in frame (image y)
    bbox_cy: np.ndarray
    bbox_h: np.ndarray
    bbox_speed: np.ndarray
    body_line_residual: np.ndarray  # shoulder-hip-ankle colinearity residual
    splash_cue: np.ndarray
    waterline_y: np.ndarray  # estimated waterline in image coords
    pose_confidence: np.ndarray
    ankle_visible: np.ndarray
    hip_visible: np.ndarray
    wrist_visible: np.ndarray
    feet_obscured: np.ndarray


def extract_underwater_signals(
    smoothed_poses: list[dict[str, Any]],
    *,
    track_observations: list[dict[str, Any]] | None = None,
    frame_splash_scores: dict[int, float] | None = None,
) -> UnderwaterSignals:
    ordered = sorted(
        smoothed_poses,
        key=lambda p: (float(p.get("timestamp_ms") or 0), int(p.get("frame_number") or 0)),
    )
    n = len(ordered)
    empty = np.asarray([], dtype=np.float64)
    if n == 0:
        return UnderwaterSignals(
            frame_numbers=np.asarray([], dtype=np.int32),
            timestamps_ms=empty,
            timestamps_s=empty,
            ankle_y=empty,
            left_ankle_y=empty,
            right_ankle_y=empty,
            knee_y=empty,
            hip_y=empty,
            hip_x=empty,
            shoulder_y=empty,
            wrist_y=empty,
            wrist_activity=empty,
            body_depth_proxy=empty,
            bbox_cy=empty,
            bbox_h=empty,
            bbox_speed=empty,
            body_line_residual=empty,
            splash_cue=empty,
            waterline_y=empty,
            pose_confidence=empty,
            ankle_visible=empty,
            hip_visible=empty,
            wrist_visible=empty,
            feet_obscured=empty,
        )

    frames = np.zeros(n, dtype=np.int32)
    ts = np.zeros(n, dtype=np.float64)
    lay = np.full(n, np.nan)
    ray = np.full(n, np.nan)
    lky = np.full(n, np.nan)
    rky = np.full(n, np.nan)
    lhy = np.full(n, np.nan)
    rhy = np.full(n, np.nan)
    lhx = np.full(n, np.nan)
    rhx = np.full(n, np.nan)
    lsy = np.full(n, np.nan)
    rsy = np.full(n, np.nan)
    lwx = np.full(n, np.nan)
    rwx = np.full(n, np.nan)
    lwy = np.full(n, np.nan)
    rwy = np.full(n, np.nan)
    pose_conf = np.zeros(n)
    av = np.zeros(n)
    hv = np.zeros(n)
    wv = np.zeros(n)
    feet_obs = np.zeros(n)
    bbox_cy = np.full(n, np.nan)
    bbox_h = np.full(n, np.nan)
    splash = np.zeros(n)

    obs_by_frame: dict[int, dict[str, Any]] = {}
    for obs in track_observations or []:
        obs_by_frame[int(obs.get("frame_number", -1))] = obs

    for i, pose in enumerate(ordered):
        frames[i] = int(pose.get("frame_number") or i)
        ts[i] = float(pose.get("timestamp_ms") or 0.0)
        pose_conf[i] = float(pose.get("overall_pose_confidence") or 0.0)

        _, lay[i], _, lq = _kp_xy(pose, "left_ankle")
        _, ray[i], _, rq = _kp_xy(pose, "right_ankle")
        _, lky[i], _, _ = _kp_xy(pose, "left_knee")
        _, rky[i], _, _ = _kp_xy(pose, "right_knee")
        lhx[i], lhy[i], _, lhq = _kp_xy(pose, "left_hip")
        rhx[i], rhy[i], _, rhq = _kp_xy(pose, "right_hip")
        _, lsy[i], _, _ = _kp_xy(pose, "left_shoulder")
        _, rsy[i], _, _ = _kp_xy(pose, "right_shoulder")
        lwx[i], lwy[i], _, lwq = _kp_xy(pose, "left_wrist")
        rwx[i], rwy[i], _, rwq = _kp_xy(pose, "right_wrist")

        av[i] = 0.5 * (float(lq in {"valid", "interpolated"}) + float(rq in {"valid", "interpolated"}))
        hv[i] = 0.5 * (float(lhq in {"valid", "interpolated"}) + float(rhq in {"valid", "interpolated"}))
        wv[i] = 0.5 * (float(lwq in {"valid", "interpolated"}) + float(rwq in {"valid", "interpolated"}))
        feet_obs[i] = float(av[i] < 0.5)

        crop = pose.get("crop_coordinates") or [0, 0, 0, 0]
        if len(crop) >= 4:
            x1, y1, x2, y2 = map(float, crop[:4])
            bbox_cy[i] = 0.5 * (y1 + y2)
            bbox_h[i] = max(1.0, y2 - y1)

        obs = obs_by_frame.get(frames[i])
        if obs and obs.get("bbox"):
            bb = obs["bbox"]
            if len(bb) >= 4:
                x1, y1, x2, y2 = map(float, bb[:4])
                bbox_cy[i] = 0.5 * (y1 + y2)
                bbox_h[i] = max(1.0, y2 - y1)

        # Pose-level splash / bubble cue if provided by upstream or fixture
        qflags = pose.get("quality_flags") or []
        if "splash_obscured" in qflags or "bubbles" in qflags:
            splash[i] = 0.8
        if frame_splash_scores and frames[i] in frame_splash_scores:
            splash[i] = max(splash[i], float(frame_splash_scores[frames[i]]))

    def mean2(a: np.ndarray, b: np.ndarray) -> np.ndarray:
        return np.where(np.isnan(a), b, np.where(np.isnan(b), a, 0.5 * (a + b)))

    ankle_y = mean2(lay, ray)
    knee_y = mean2(lky, rky)
    hip_y = mean2(lhy, rhy)
    hip_x = mean2(lhx, rhx)
    shoulder_y = mean2(lsy, rsy)
    wrist_y = mean2(lwy, rwy)
    wrist_x = mean2(lwx, rwx)

    # Wrist activity: absolute derivative of wrist x (recovery/pull when high)
    wrist_activity = np.zeros(n)
    if n >= 2:
        dt = np.diff(ts / 1000.0, prepend=(ts[0] / 1000.0))
        dt[dt <= 1e-6] = np.median(dt[dt > 1e-6]) if np.any(dt > 1e-6) else 1 / 30
        wx = wrist_x.copy()
        # fill for derivative only
        good = np.isfinite(wx)
        if good.sum() >= 2:
            idx = np.arange(n)
            wx[~good] = np.interp(idx[~good], idx[good], wx[good])
            wrist_activity = np.abs(np.gradient(wx, ts / 1000.0))

    body_depth = mean2(hip_y, ankle_y)

    bbox_speed = np.zeros(n)
    if n >= 2 and np.any(np.isfinite(bbox_cy)):
        cy = bbox_cy.copy()
        good = np.isfinite(cy)
        if good.sum() >= 2:
            idx = np.arange(n)
            cy[~good] = np.interp(idx[~good], idx[good], cy[good])
            bbox_speed = np.abs(np.gradient(cy, ts / 1000.0))

    # Body-line residual: distance of hip from shoulder–ankle line in y (proxy)
    residual = np.full(n, np.nan)
    for i in range(n):
        if np.isfinite(shoulder_y[i]) and np.isfinite(hip_y[i]) and np.isfinite(ankle_y[i]):
            # expected hip y if linear between shoulder and ankle at mid
            expected = 0.5 * (shoulder_y[i] + ankle_y[i])
            residual[i] = abs(hip_y[i] - expected)

    # Waterline estimate: robust upper-third of visible shoulder_y during early clip
    finite_sh = shoulder_y[np.isfinite(shoulder_y)]
    waterline = float(np.nanpercentile(finite_sh, 35)) if finite_sh.size else 0.0
    waterline_y = np.full(n, waterline)

    return UnderwaterSignals(
        frame_numbers=frames,
        timestamps_ms=ts,
        timestamps_s=ts / 1000.0,
        ankle_y=ankle_y,
        left_ankle_y=lay,
        right_ankle_y=ray,
        knee_y=knee_y,
        hip_y=hip_y,
        hip_x=hip_x,
        shoulder_y=shoulder_y,
        wrist_y=wrist_y,
        wrist_activity=wrist_activity,
        body_depth_proxy=body_depth,
        bbox_cy=bbox_cy,
        bbox_h=bbox_h,
        bbox_speed=bbox_speed,
        body_line_residual=residual,
        splash_cue=splash,
        waterline_y=waterline_y,
        pose_confidence=pose_conf,
        ankle_visible=av,
        hip_visible=hv,
        wrist_visible=wv,
        feet_obscured=feet_obs,
    )

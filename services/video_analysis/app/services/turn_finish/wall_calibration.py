"""Pool-wall calibration for turn / finish analysis (Milestone 7)."""

from __future__ import annotations

from typing import Any

import numpy as np

from app.services.butterfly.signals import _kp_xy
from app.services.turn_finish.types import WallCalibration, confidence_label


def calibrate_wall(
    *,
    smoothed_poses: list[dict[str, Any]],
    frame_width: int | None = None,
    frame_height: int | None = None,
    manual_wall_line: dict[str, Any] | None = None,
    pool_geometry: dict[str, Any] | None = None,
    lane_line_termination_x: float | None = None,
    starting_block_x: float | None = None,
    auto_detect: bool = True,
    image_bgr: Any | None = None,
) -> WallCalibration:
    """
    Resolve wall position with explicit method + confidence.

    Priority:
      1. manually selected wall line
      2. known pool geometry
      3. starting-block location
      4. lane-line termination
      5. automatic edge / trajectory asymptote when reliable
      6. unavailable
    """
    width = frame_width
    if width is None and smoothed_poses:
        # Infer from crop extents
        xs = []
        for p in smoothed_poses:
            crop = p.get("crop_coordinates") or []
            if len(crop) >= 4:
                xs.extend([float(crop[0]), float(crop[2])])
            for name in ("left_wrist", "right_wrist", "left_ankle", "nose"):
                x, _, _, q = _kp_xy(p, name)
                if q in {"valid", "interpolated"} and np.isfinite(x):
                    xs.append(float(x))
        if xs:
            width = int(max(640, np.ceil(max(xs) * 1.05)))

    limitations: list[str] = []
    flags: list[str] = []

    # 1) Manual
    if manual_wall_line:
        wall_x = manual_wall_line.get("x")
        if wall_x is None and "x1" in manual_wall_line:
            wall_x = 0.5 * (float(manual_wall_line["x1"]) + float(manual_wall_line.get("x2", manual_wall_line["x1"])))
        if wall_x is not None:
            side = _side(float(wall_x), width)
            conf = float(manual_wall_line.get("confidence", 0.95))
            mpp = None
            if pool_geometry and pool_geometry.get("meters_per_pixel") is not None:
                mpp = float(pool_geometry["meters_per_pixel"])
            return WallCalibration(
                wall_x=float(wall_x),
                wall_side=side,
                method="manual_wall_line",
                confidence=conf,
                confidence_label=confidence_label(conf),
                frame_width=width,
                meters_per_pixel=mpp,
                quality_flags=["user_provided"],
                supporting_frames=list(manual_wall_line.get("supporting_frames") or []),
                notes="Manually selected wall line",
            )

    # 2) Pool geometry
    if pool_geometry and pool_geometry.get("wall_x") is not None:
        wall_x = float(pool_geometry["wall_x"])
        conf = float(pool_geometry.get("confidence", 0.8))
        return WallCalibration(
            wall_x=wall_x,
            wall_side=_side(wall_x, width),
            method="pool_geometry",
            confidence=conf,
            confidence_label=confidence_label(conf),
            frame_width=width,
            meters_per_pixel=float(pool_geometry["meters_per_pixel"])
            if pool_geometry.get("meters_per_pixel") is not None
            else None,
            quality_flags=["known_pool_geometry"],
            supporting_frames=[],
            notes="Known pool geometry mapping",
        )

    # 3) Starting block
    if starting_block_x is not None:
        wall_x = float(starting_block_x)
        conf = 0.7
        return WallCalibration(
            wall_x=wall_x,
            wall_side=_side(wall_x, width),
            method="starting_block",
            confidence=conf,
            confidence_label=confidence_label(conf),
            frame_width=width,
            quality_flags=["starting_block_visible"],
            notes="Wall inferred from starting-block location",
        )

    # 4) Lane-line termination
    if lane_line_termination_x is not None:
        wall_x = float(lane_line_termination_x)
        conf = 0.65
        return WallCalibration(
            wall_x=wall_x,
            wall_side=_side(wall_x, width),
            method="lane_line_termination",
            confidence=conf,
            confidence_label=confidence_label(conf),
            frame_width=width,
            quality_flags=["lane_line_termination"],
            notes="Wall inferred from lane-line termination",
        )

    # 5) Automatic
    if auto_detect:
        auto = _auto_wall(
            smoothed_poses=smoothed_poses,
            frame_width=width,
            image_bgr=image_bgr,
        )
        if auto is not None:
            return auto
        flags.append("auto_wall_unreliable")
        limitations.append("automatic_wall_detection_not_reliable")

    limitations.append("wall_calibration_unavailable")
    return WallCalibration(
        wall_x=None,
        wall_side="unknown",
        method="unavailable",
        confidence=0.0,
        confidence_label="unavailable",
        frame_width=width,
        quality_flags=flags,
        limitations=limitations,
        notes="No reliable wall calibration source",
    )


def _side(wall_x: float, width: int | None) -> str:
    if width is None:
        return "unknown"
    return "left" if wall_x < 0.5 * width else "right"


def _auto_wall(
    *,
    smoothed_poses: list[dict[str, Any]],
    frame_width: int | None,
    image_bgr: Any | None,
) -> WallCalibration | None:
    """
    Automatic wall estimate:
      - optional image vertical-edge near border
      - trajectory asymptote of hip/wrist approaching an extreme x
    """
    edge_x = None
    edge_conf = 0.0
    if image_bgr is not None:
        try:
            import cv2

            gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
            edges = cv2.Canny(gray, 80, 160)
            h, w = edges.shape[:2]
            # Sum edges in left/right vertical bands
            band = max(4, w // 20)
            left_score = float(np.mean(edges[:, :band]))
            right_score = float(np.mean(edges[:, -band:]))
            if max(left_score, right_score) > 8.0 and abs(left_score - right_score) > 2.0:
                if right_score > left_score:
                    edge_x = float(w - band // 2)
                else:
                    edge_x = float(band // 2)
                edge_conf = min(0.75, max(left_score, right_score) / 40.0)
                frame_width = w
        except Exception:  # noqa: BLE001
            edge_x = None

    # Trajectory asymptote: hip_x approaching min or max
    hips = []
    frames = []
    for p in sorted(smoothed_poses, key=lambda x: int(x.get("frame_number") or 0)):
        lx, _, _, lq = _kp_xy(p, "left_hip")
        rx, _, _, rq = _kp_xy(p, "right_hip")
        vals = [v for v, q in ((lx, lq), (rx, rq)) if q in {"valid", "interpolated"} and np.isfinite(v)]
        if vals:
            hips.append(float(np.mean(vals)))
            frames.append(int(p.get("frame_number") or 0))
    traj_x = None
    traj_conf = 0.0
    if len(hips) >= 8:
        arr = np.asarray(hips, dtype=np.float64)
        # Direction of travel in second half
        mid = len(arr) // 2
        delta = float(np.nanmean(arr[mid:]) - np.nanmean(arr[:mid]))
        if abs(delta) > 5.0:
            # Wall is ahead of travel direction: extreme of trajectory + margin
            if delta > 0:
                traj_x = float(np.nanmax(arr) + 20.0)
                side_hint = "right"
            else:
                traj_x = float(np.nanmin(arr) - 20.0)
                side_hint = "left"
            # Confidence from monotonicity
            diffs = np.diff(arr)
            agree = float(np.mean(diffs > 0)) if delta > 0 else float(np.mean(diffs < 0))
            traj_conf = float(np.clip(0.35 + 0.5 * agree, 0, 0.8))
            if frame_width is not None:
                # If asymptote is outside frame, keep but mark
                pass
            _ = side_hint

    # Prefer image edge if both available and agree roughly
    if edge_x is not None and traj_x is not None:
        if abs(edge_x - traj_x) < 0.15 * (frame_width or 640):
            wall_x = 0.5 * (edge_x + traj_x)
            conf = min(0.85, 0.5 * (edge_conf + traj_conf) + 0.2)
            return WallCalibration(
                wall_x=wall_x,
                wall_side=_side(wall_x, frame_width),
                method="auto_edge",
                confidence=conf,
                confidence_label=confidence_label(conf),
                frame_width=frame_width,
                quality_flags=["auto_edge_and_trajectory_agree"],
                supporting_frames=frames[-5:],
                notes="Automatic wall from edge + trajectory agreement",
            )

    if edge_x is not None and edge_conf >= 0.45:
        return WallCalibration(
            wall_x=edge_x,
            wall_side=_side(edge_x, frame_width),
            method="auto_edge",
            confidence=edge_conf,
            confidence_label=confidence_label(edge_conf),
            frame_width=frame_width,
            quality_flags=["auto_vertical_edge"],
            supporting_frames=[],
            notes="Automatic wall from vertical edge band",
        )

    if traj_x is not None and traj_conf >= 0.55:
        flags = ["trajectory_asymptote"]
        lim = []
        if frame_width is not None and (traj_x < 0 or traj_x > frame_width):
            flags.append("wall_may_be_outside_frame")
            lim.append("wall_outside_or_near_border")
        return WallCalibration(
            wall_x=traj_x,
            wall_side=_side(traj_x, frame_width),
            method="trajectory_asymptote",
            confidence=traj_conf,
            confidence_label=confidence_label(traj_conf),
            frame_width=frame_width,
            quality_flags=flags,
            limitations=lim,
            supporting_frames=frames[-5:],
            notes="Wall inferred from swimmer trajectory asymptote",
        )

    return None

"""Diagnostic skeleton overlay and pose-quality artifacts (Milestone 4)."""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

import cv2
import numpy as np

from app.domain.landmarks import BODY_EDGES
from app.services.pose_smoother import PoseCoverageStats, SmoothingParams

logger = logging.getLogger(__name__)

# Visual distinction: raw / interpolated / low-confidence
_COLOR_RAW = (80, 220, 80)  # green BGR
_COLOR_INTERP = (0, 200, 255)  # amber
_COLOR_LOW = (0, 140, 255)  # orange
_COLOR_OTHER = (160, 160, 160)
_EDGE_COLOR = (220, 220, 220)


def _point_color(quality: str) -> tuple[int, int, int]:
    if quality == "interpolated":
        return _COLOR_INTERP
    if quality == "low_confidence":
        return _COLOR_LOW
    if quality == "valid":
        return _COLOR_RAW
    return _COLOR_OTHER


def _draw_skeleton(
    frame: np.ndarray,
    pose: dict[str, Any],
    *,
    min_draw_confidence: float,
) -> None:
    pts: dict[str, tuple[float, float, str]] = {}
    for kp in pose.get("keypoints") or []:
        name = str(kp.get("name") or "")
        x, y = kp.get("x"), kp.get("y")
        if x is None or y is None:
            continue
        quality = str(kp.get("quality_flag") or "unavailable")
        conf = float(kp.get("confidence") or 0.0)
        if quality in {"unavailable", "occluded", "outlier_removed"}:
            continue
        if quality == "low_confidence":
            continue
        if quality == "valid" and conf < min_draw_confidence:
            continue
        pts[name] = (float(x), float(y), quality)

    for a, b in BODY_EDGES:
        if a not in pts or b not in pts:
            continue
        x1, y1, _ = pts[a]
        x2, y2, _ = pts[b]
        cv2.line(
            frame,
            (int(round(x1)), int(round(y1))),
            (int(round(x2)), int(round(y2))),
            _EDGE_COLOR,
            2,
            cv2.LINE_AA,
        )

    for name, (x, y, q) in pts.items():
        color = _point_color(q)
        radius = 5 if q == "interpolated" else 4
        cv2.circle(frame, (int(round(x)), int(round(y))), radius, color, -1, cv2.LINE_AA)
        if q == "interpolated":
            cv2.circle(frame, (int(round(x)), int(round(y))), radius + 2, color, 1, cv2.LINE_AA)


def _hud(
    frame: np.ndarray,
    *,
    job_id: str,
    frame_index: int,
    timestamp_s: float,
    track_id: str | int | None,
    pose_confidence: float,
) -> None:
    lines = [
        f"job={job_id}",
        f"frame={frame_index}  t={timestamp_s:.3f}s",
        f"track={track_id if track_id is not None else '-'}",
        f"pose_conf={pose_confidence:.3f}",
        "green=raw  amber=interp  orange=low_conf",
    ]
    y = 22
    for line in lines:
        cv2.putText(frame, line, (12, y), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 0, 0), 3, cv2.LINE_AA)
        cv2.putText(frame, line, (12, y), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1, cv2.LINE_AA)
        y += 22


def render_skeleton_overlay(
    video_path: Path,
    smoothed_poses: list[dict[str, Any]],
    output_path: Path,
    *,
    job_id: str,
    min_draw_confidence: float = 0.25,
) -> Path:
    """
    Draw skeleton overlays on the original video timeline.

    Uses full-frame landmark coordinates (mapped without crop distortion in M3).
    Retains original aspect ratio (no canvas resize).
    """
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Unable to open video for overlay: {video_path}")

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = float(cap.get(cv2.CAP_PROP_FPS) or 30.0)
    if fps <= 0:
        fps = 30.0

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(output_path), fourcc, fps, (width, height))
    if not writer.isOpened():
        cap.release()
        raise RuntimeError(f"Unable to open overlay writer: {output_path}")

    by_index = {int(p.get("frame_number", -1)): p for p in smoothed_poses}
    idx = 0
    try:
        while True:
            ok, frame = cap.read()
            if not ok:
                break
            pf = by_index.get(idx)
            if pf is not None:
                _draw_skeleton(frame, pf, min_draw_confidence=min_draw_confidence)
                ts_ms = float(pf.get("timestamp_ms") or (idx / fps * 1000.0))
                _hud(
                    frame,
                    job_id=job_id,
                    frame_index=int(pf.get("frame_number", idx)),
                    timestamp_s=ts_ms / 1000.0,
                    track_id=pf.get("swimmer_track_id"),
                    pose_confidence=float(pf.get("overall_pose_confidence") or 0.0),
                )
            else:
                _hud(
                    frame,
                    job_id=job_id,
                    frame_index=idx,
                    timestamp_s=idx / fps,
                    track_id=None,
                    pose_confidence=0.0,
                )
            writer.write(frame)
            idx += 1
    finally:
        writer.release()
        cap.release()

    logger.info("Wrote skeleton overlay video=%s frames=%s", output_path, idx)
    return output_path


def export_diagnostic_frames(
    video_path: Path,
    smoothed_poses: list[dict[str, Any]],
    output_dir: Path,
    *,
    job_id: str,
    max_frames: int = 12,
    min_draw_confidence: float = 0.25,
) -> list[Path]:
    """Export evenly spaced diagnostic stills with overlay."""
    output_dir.mkdir(parents=True, exist_ok=True)
    if not smoothed_poses:
        return []

    indices = np.linspace(
        0, len(smoothed_poses) - 1, num=min(max_frames, len(smoothed_poses)), dtype=int
    )
    selected = [smoothed_poses[int(i)] for i in sorted(set(indices.tolist()))]

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Unable to open video for diagnostics: {video_path}")

    paths: list[Path] = []
    try:
        for pf in selected:
            frame_number = int(pf.get("frame_number", 0))
            cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
            ok, frame = cap.read()
            if not ok:
                continue
            _draw_skeleton(frame, pf, min_draw_confidence=min_draw_confidence)
            ts_ms = float(pf.get("timestamp_ms") or 0.0)
            _hud(
                frame,
                job_id=job_id,
                frame_index=frame_number,
                timestamp_s=ts_ms / 1000.0,
                track_id=pf.get("swimmer_track_id"),
                pose_confidence=float(pf.get("overall_pose_confidence") or 0.0),
            )
            out = output_dir / f"frame_{frame_number:06d}.jpg"
            cv2.imwrite(str(out), frame, [int(cv2.IMWRITE_JPEG_QUALITY), 92])
            paths.append(out)
    finally:
        cap.release()
    return paths


def write_pose_quality_report(
    path: Path,
    *,
    job_id: str,
    coverage: PoseCoverageStats,
    params: SmoothingParams,
    filter_method: str,
    limitations: list[str] | None = None,
) -> Path:
    payload = {
        "job_id": job_id,
        "filter_method": filter_method,
        "parameters": params.__dict__.copy(),
        "coverage": coverage.to_dict(),
        "limitations": limitations or [],
        "notes": [
            "Raw RTMPose output is preserved unchanged in raw_pose.json.",
            "Smoothed poses never interpolate across long occlusions.",
            "Low-confidence noise is not smoothed into apparently valid movement.",
        ],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return path


def write_frame_confidence_data(path: Path, frame_confidence: list[dict[str, Any]]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"frames": frame_confidence}, indent=2), encoding="utf-8")
    return path


def write_smoothed_pose_json(
    path: Path,
    *,
    job_id: str,
    video_id: str,
    smoothed_poses: list[dict[str, Any]],
    filter_method: str,
    coverage: PoseCoverageStats,
) -> Path:
    payload = {
        "job_id": job_id,
        "video_id": video_id,
        "dataset": "smoothed",
        "filter_method": filter_method,
        "coverage": coverage.to_dict(),
        "poses": smoothed_poses,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return path


def map_overlay_point_from_crop(
    x_crop: float,
    y_crop: float,
    crop_box: tuple[float, float, float, float] | list[float],
) -> tuple[float, float]:
    """
    Map a crop-space landmark to full-frame without aspect distortion.

    Crop boxes are axis-aligned pixel regions; mapping is pure translation
    at the source frame scale (no stretch/squash).
    """
    x1, y1 = float(crop_box[0]), float(crop_box[1])
    return float(x_crop) + x1, float(y_crop) + y1

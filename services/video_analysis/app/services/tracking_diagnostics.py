"""Write Milestone 2 tracking diagnostic artifacts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import cv2
import numpy as np

from app.services.swimmer_tracker import Track
from app.services.target_selector import TargetSelectionResult


def write_json(path: Path, payload: Any) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return str(path.resolve())


def build_tracking_quality_summary(
    *,
    tracks: list[Track],
    target: TargetSelectionResult,
    processed_frames: int,
    frames_with_detections: int,
    events: list[dict[str, Any]],
    target_coverage: float,
    lost_extended: bool,
) -> dict[str, Any]:
    active = [t for t in tracks if t.active]
    return {
        "processed_frames": processed_frames,
        "frames_with_detections": frames_with_detections,
        "detection_frame_ratio": (
            frames_with_detections / processed_frames if processed_frames else 0.0
        ),
        "track_count": len(tracks),
        "active_track_count": len(active),
        "target_track_id": target.track_id,
        "target_identity_confidence": target.confidence,
        "target_uncertain": target.uncertain,
        "target_coverage": target_coverage,
        "lost_extended": lost_extended,
        "event_counts": _count_events(events),
        "per_track_confidence": {
            t.track_id: t.tracking_confidence() for t in tracks
        },
    }


def _count_events(events: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for event in events:
        key = str(event.get("type", "unknown"))
        counts[key] = counts.get(key, 0) + 1
    return counts


def save_target_frames(
    *,
    video_path: Path,
    out_dir: Path,
    target_track: Track | None,
    max_frames: int = 8,
) -> list[str]:
    out_dir.mkdir(parents=True, exist_ok=True)
    if target_track is None or not target_track.observations:
        return []

    obs = target_track.observations
    step = max(1, len(obs) // max_frames)
    selected = obs[::step][:max_frames]
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return []

    paths: list[str] = []
    for item in selected:
        cap.set(cv2.CAP_PROP_POS_FRAMES, item.frame_number)
        ok, frame = cap.read()
        if not ok or frame is None:
            continue
        x1, y1, x2, y2 = [int(v) for v in item.bbox]
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 255), 2)
        cv2.putText(
            frame,
            f"{target_track.track_id}",
            (x1, max(20, y1 - 8)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 255),
            2,
        )
        out = out_dir / f"target_frame_{item.frame_number:06d}.jpg"
        cv2.imwrite(str(out), frame)
        paths.append(str(out.resolve()))
    cap.release()
    return paths


def write_annotated_tracking_video(
    *,
    video_path: Path,
    out_path: Path,
    tracks: list[Track],
    target_track_id: str | None,
    frame_interval: int,
    fps: float,
    max_frames: int | None = None,
) -> str | None:
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return None

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    src_fps = cap.get(cv2.CAP_PROP_FPS) or fps or 30.0
    out_path.parent.mkdir(parents=True, exist_ok=True)
    writer = cv2.VideoWriter(
        str(out_path),
        cv2.VideoWriter_fourcc(*"mp4v"),
        src_fps / max(1, frame_interval),
        (width, height),
    )

    # Index observations by frame for quick draw
    by_frame: dict[int, list[tuple[Track, list[float]]]] = {}
    for track in tracks:
        for obs in track.observations:
            by_frame.setdefault(obs.frame_number, []).append((track, obs.bbox))

    frame_idx = 0
    while True:
        if max_frames is not None and frame_idx >= max_frames:
            break
        ok, frame = cap.read()
        if not ok:
            break
        if frame_idx % max(1, frame_interval) == 0:
            for track, bbox in by_frame.get(frame_idx, []):
                x1, y1, x2, y2 = [int(v) for v in bbox]
                is_target = track.track_id == target_track_id
                color = (0, 255, 255) if is_target else (80, 180, 80)
                thickness = 3 if is_target else 2
                cv2.rectangle(frame, (x1, y1), (x2, y2), color, thickness)
                label = track.track_id + (" *" if is_target else "")
                cv2.putText(
                    frame,
                    label,
                    (x1, max(20, y1 - 6)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.55,
                    color,
                    2,
                )
            writer.write(frame)
        frame_idx += 1

    cap.release()
    writer.release()
    if not out_path.exists() or out_path.stat().st_size == 0:
        return None
    return str(out_path.resolve())


def compute_target_coverage(track: Track | None, processed_frames: int) -> float:
    if not track or processed_frames <= 0:
        return 0.0
    frames = {o.frame_number for o in track.observations}
    return len(frames) / float(processed_frames)

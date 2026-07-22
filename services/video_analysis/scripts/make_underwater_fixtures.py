#!/usr/bin/env python3
"""Generate manually labeled underwater / kick / breakout fixtures for Milestone 6."""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tests" / "fixtures" / "underwater"

CORE = [
    "nose",
    "left_shoulder",
    "right_shoulder",
    "left_elbow",
    "right_elbow",
    "left_wrist",
    "right_wrist",
    "left_hip",
    "right_hip",
    "left_knee",
    "right_knee",
    "left_ankle",
    "right_ankle",
]


def _set(kps: list[dict], name: str, x: float, y: float, conf: float = 0.9, flag: str = "valid") -> None:
    payload = {
        "name": name,
        "x": float(x) if flag in {"valid", "interpolated"} else None,
        "y": float(y) if flag in {"valid", "interpolated"} else None,
        "z": None,
        "confidence": conf,
        "x_crop": float(x) if flag in {"valid", "interpolated"} else None,
        "y_crop": float(y) if flag in {"valid", "interpolated"} else None,
        "quality_flag": flag,
    }
    for i, kp in enumerate(kps):
        if kp.get("name") == name:
            kps[i] = payload
            return
    kps.append(payload)


def synthesize(
    *,
    name: str,
    fps: float = 30.0,
    n_kicks: int = 5,
    kick_period_s: float = 0.45,
    already_underwater: bool = False,
    after_breakout_only: bool = False,
    no_water_entry: bool = False,
    feet_obscured: bool = False,
    bubbles: bool = False,
    view: str = "side",
    short_clip: bool = False,
    surface_only: bool = False,
    camera_motion: bool = False,
) -> tuple[list[dict], dict, list[dict]]:
    """
    Timeline (seconds):
      [0, entry) dive/approach (optional)
      [entry, breakout) underwater dolphin kicks
      [breakout, end) first surface strokes
    """
    if after_breakout_only:
        # Surface swimming only after breakout
        duration = 2.4
        times = [i / fps for i in range(int(duration * fps))]
        poses = []
        surface_entries = []
        for fi, t in enumerate(times):
            phase = (t % 1.2) / 1.2
            poses.append(_surface_pose(fi, t, phase, camera_motion=camera_motion))
            if abs(phase) < 1e-6 or abs(phase - 0) < 0.02:
                if fi % int(round(1.2 * fps)) == 0:
                    surface_entries.append(fi)
        # ensure a few entries
        surface_entries = list(range(0, len(times), int(round(1.2 * fps))))
        labels = {
            "name": name,
            "view": view,
            "fps": fps,
            "kick_frames": [],
            "kick_count": 0,
            "water_entry_frame": None,
            "underwater_start_frame": None,
            "underwater_end_frame": None,
            "breakout_frame": None,
            "first_surface_stroke_frame": surface_entries[0] if surface_entries else 0,
            "notes": "Clip begins after breakout; surface only.",
            "scenario": "after_breakout",
        }
        tracks = _tracks_from_poses(poses, camera_motion=camera_motion)
        return poses, labels, tracks

    if surface_only:
        duration = 2.0
        times = [i / fps for i in range(int(duration * fps))]
        poses = [_surface_pose(i, t, (t % 1.1) / 1.1) for i, t in enumerate(times)]
        labels = {
            "name": name,
            "view": view,
            "fps": fps,
            "kick_frames": [],
            "kick_count": 0,
            "water_entry_frame": None,
            "underwater_start_frame": None,
            "underwater_end_frame": None,
            "breakout_frame": None,
            "first_surface_stroke_frame": None,
            "notes": "No valid underwater phase.",
            "scenario": "surface_only",
        }
        return poses, labels, _tracks_from_poses(poses)

    if short_clip:
        duration = 0.35
        times = [i / fps for i in range(max(3, int(duration * fps)))]
        poses = []
        for fi, t in enumerate(times):
            poses.append(_underwater_pose(fi, t, kick_phase=t / kick_period_s, feet_obscured=feet_obscured, bubbles=bubbles))
        labels = {
            "name": name,
            "view": view,
            "fps": fps,
            "kick_frames": [],
            "kick_count": 0,
            "water_entry_frame": 0 if already_underwater else None,
            "underwater_start_frame": 0,
            "underwater_end_frame": len(times) - 1,
            "breakout_frame": None,
            "first_surface_stroke_frame": None,
            "notes": "Short clip.",
            "scenario": "short_clip",
        }
        return poses, labels, _tracks_from_poses(poses)

    entry_t = 0.0 if already_underwater else 0.35
    uw_dur = n_kicks * kick_period_s
    breakout_t = entry_t + uw_dur
    end_t = breakout_t + 1.5
    times = [i / fps for i in range(int(round(end_t * fps)) + 1)]

    # Kick peaks at mid of each kick period after entry
    kick_times = [entry_t + (i + 0.5) * kick_period_s for i in range(n_kicks)]
    kick_frames = [int(round(kt * fps)) for kt in kick_times]
    entry_frame = None if (already_underwater or no_water_entry) else int(round(entry_t * fps))
    uw_start = int(round(entry_t * fps))
    breakout_frame = int(round(breakout_t * fps))
    first_stroke_frame = breakout_frame
    # Additional surface entries after breakout
    surface_entries = [breakout_frame]
    t = breakout_t + 1.2
    while t < end_t:
        surface_entries.append(int(round(t * fps)))
        t += 1.2

    poses = []
    splash_scores = {}
    for fi, t in enumerate(times):
        if t < entry_t:
            pose = _dive_pose(fi, t, bubbles=bubbles)
            if abs(t - entry_t) < 1.5 / fps:
                pose["quality_flags"] = ["splash_obscured"]
                splash_scores[fi] = 0.9
        elif t < breakout_t:
            phase = (t - entry_t) / kick_period_s
            pose = _underwater_pose(
                fi,
                t,
                kick_phase=phase,
                feet_obscured=feet_obscured,
                bubbles=bubbles,
                underwater_view=view.startswith("underwater"),
            )
            if bubbles:
                pose["quality_flags"] = list(set((pose.get("quality_flags") or []) + ["bubbles"]))
                splash_scores[fi] = max(splash_scores.get(fi, 0.0), 0.6)
        else:
            phase = ((t - breakout_t) % 1.2) / 1.2
            pose = _surface_pose(fi, t, phase, camera_motion=camera_motion)
        poses.append(pose)

    if no_water_entry:
        entry_frame = None
        # remove splash flags near start
        for p in poses[: max(1, uw_start + 1)]:
            p["quality_flags"] = [f for f in (p.get("quality_flags") or []) if f != "splash_obscured"]

    labels = {
        "name": name,
        "view": view,
        "fps": fps,
        "kick_frames": kick_frames,
        "kick_count": n_kicks,
        "water_entry_frame": entry_frame,
        "underwater_start_frame": uw_start,
        "underwater_end_frame": breakout_frame,
        "breakout_frame": breakout_frame,
        "breakout_timestamp_ms": breakout_t * 1000.0,
        "first_surface_stroke_frame": first_stroke_frame,
        "surface_stroke_entry_frames": surface_entries,
        "splash_scores": splash_scores,
        "notes": "Manually labeled synthetic underwater dolphin-kick + breakout sequence.",
        "scenario": "standard",
    }
    return poses, labels, _tracks_from_poses(poses, camera_motion=camera_motion)


def _dive_pose(fi: int, t: float, bubbles: bool = False) -> dict:
    mid_x = 120 + t * 40
    sh_y = 160 + t * 30
    kps: list[dict] = []
    _set(kps, "left_shoulder", mid_x - 30, sh_y)
    _set(kps, "right_shoulder", mid_x + 30, sh_y)
    _set(kps, "left_hip", mid_x - 20, sh_y + 50)
    _set(kps, "right_hip", mid_x + 20, sh_y + 50)
    _set(kps, "left_knee", mid_x - 18, sh_y + 90)
    _set(kps, "right_knee", mid_x + 18, sh_y + 90)
    _set(kps, "left_ankle", mid_x - 16, sh_y + 130)
    _set(kps, "right_ankle", mid_x + 16, sh_y + 130)
    _set(kps, "left_wrist", mid_x - 40, sh_y + 20)
    _set(kps, "right_wrist", mid_x + 40, sh_y + 20)
    _set(kps, "nose", mid_x, sh_y - 25)
    return _pose_dict(fi, t, kps, y1=sh_y - 40, y2=sh_y + 150)


def _underwater_pose(
    fi: int,
    t: float,
    *,
    kick_phase: float,
    feet_obscured: bool = False,
    bubbles: bool = False,
    underwater_view: bool = False,
) -> dict:
    mid_x = 140 + t * 55
    # deeper in image
    base_y = 260 if not underwater_view else 220
    # dolphin undulation
    wave = 18.0 * math.sin(2 * math.pi * kick_phase)
    hip_y = base_y + 0.6 * wave
    knee_y = base_y + 45 + wave
    ankle_y = base_y + 85 + 1.4 * wave
    sh_y = base_y - 40 - 0.3 * wave
    # wrists quiet / streamline
    wrist_y = sh_y + 10
    kps: list[dict] = []
    _set(kps, "left_shoulder", mid_x - 28, sh_y)
    _set(kps, "right_shoulder", mid_x + 28, sh_y)
    _set(kps, "left_hip", mid_x - 18, hip_y)
    _set(kps, "right_hip", mid_x + 18, hip_y)
    _set(kps, "left_knee", mid_x - 16, knee_y)
    _set(kps, "right_knee", mid_x + 16, knee_y)
    if feet_obscured:
        _set(kps, "left_ankle", mid_x - 14, ankle_y, conf=0.05, flag="low_confidence")
        _set(kps, "right_ankle", mid_x + 14, ankle_y, conf=0.05, flag="low_confidence")
    else:
        _set(kps, "left_ankle", mid_x - 14, ankle_y)
        _set(kps, "right_ankle", mid_x + 14, ankle_y)
    _set(kps, "left_wrist", mid_x - 10, wrist_y)
    _set(kps, "right_wrist", mid_x + 10, wrist_y)
    _set(kps, "left_elbow", mid_x - 16, sh_y + 8)
    _set(kps, "right_elbow", mid_x + 16, sh_y + 8)
    _set(kps, "nose", mid_x, sh_y - 20)
    flags = []
    if bubbles:
        flags.append("bubbles")
    return _pose_dict(fi, t, kps, y1=sh_y - 30, y2=ankle_y + 20, flags=flags)


def _surface_pose(fi: int, t: float, phase: float, camera_motion: bool = False) -> dict:
    mid_x = 200 + t * 40
    if camera_motion:
        mid_x += 8 * math.sin(t * 9)
    fwd = 35 * math.cos(2 * math.pi * phase)
    sh_y = 190
    kps: list[dict] = []
    _set(kps, "left_shoulder", mid_x - 30, sh_y)
    _set(kps, "right_shoulder", mid_x + 30, sh_y)
    _set(kps, "left_hip", mid_x - 20, sh_y + 55)
    _set(kps, "right_hip", mid_x + 20, sh_y + 55)
    _set(kps, "left_knee", mid_x - 18, sh_y + 95)
    _set(kps, "right_knee", mid_x + 18, sh_y + 95)
    _set(kps, "left_ankle", mid_x - 16, sh_y + 135)
    _set(kps, "right_ankle", mid_x + 16, sh_y + 135)
    _set(kps, "left_wrist", mid_x + fwd - 20, sh_y + 25 + 8 * math.sin(2 * math.pi * phase))
    _set(kps, "right_wrist", mid_x + fwd + 20, sh_y + 25 + 8 * math.sin(2 * math.pi * phase))
    _set(kps, "nose", mid_x, sh_y - 28)
    return _pose_dict(fi, t, kps, y1=sh_y - 40, y2=sh_y + 150)


def _pose_dict(fi: int, t: float, kps: list[dict], y1: float, y2: float, flags: list[str] | None = None) -> dict:
    return {
        "video_id": "uw",
        "job_id": "fixture",
        "frame_number": fi,
        "timestamp_ms": t * 1000.0,
        "swimmer_track_id": "track-1",
        "crop_coordinates": [80.0, float(y1), 400.0, float(y2)],
        "keypoints": kps,
        "overall_pose_confidence": 0.85,
        "model_name": "synthetic-underwater",
        "model_version": "m6",
        "inference_resolution": [192, 256],
        "processing_duration_ms": 1.0,
        "usable": True,
        "unusable_reason": None,
        "quality_flags": flags or [],
        "dataset": "smoothed",
    }


def _tracks_from_poses(poses: list[dict], camera_motion: bool = False) -> list[dict]:
    obs = []
    for p in poses:
        crop = p["crop_coordinates"]
        if camera_motion:
            jitter = 12 * math.sin(p["timestamp_ms"] / 1000.0 * 11)
            crop = [crop[0], crop[1] + jitter, crop[2], crop[3] + jitter]
        obs.append(
            {
                "frame_number": p["frame_number"],
                "timestamp_ms": p["timestamp_ms"],
                "bbox": crop,
            }
        )
    return obs


def write_case(name: str, poses: list[dict], labels: dict, tracks: list[dict]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.smoothed_pose.json").write_text(
        json.dumps(
            {
                "job_id": f"fixture-{name}",
                "video_id": name,
                "dataset": "smoothed",
                "filter_method": "synthetic",
                "poses": poses,
            },
            separators=(",", ":"),
        ),
        encoding="utf-8",
    )
    labels = {**labels, "track_observations": tracks}
    (OUT / f"{name}.labels.json").write_text(json.dumps(labels, indent=2), encoding="utf-8")
    print(f"wrote {name} kicks={labels.get('kick_count')} breakout={labels.get('breakout_frame')}")


def main() -> None:
    cases = [
        synthesize(name="clean_underwater_breakout", n_kicks=5, view="side"),
        synthesize(name="already_underwater_start", n_kicks=4, already_underwater=True, view="side"),
        synthesize(name="after_breakout_only", after_breakout_only=True, view="side"),
        synthesize(name="no_visible_water_entry", n_kicks=4, no_water_entry=True, already_underwater=True, view="side"),
        synthesize(name="feet_obscured", n_kicks=5, feet_obscured=True, view="side"),
        synthesize(name="bubbles_splash", n_kicks=4, bubbles=True, view="side"),
        synthesize(name="underwater_camera", n_kicks=5, view="underwater_side", already_underwater=True),
        synthesize(name="deck_view", n_kicks=4, view="deck"),
        synthesize(name="short_clip", short_clip=True, view="side"),
        synthesize(name="no_underwater_phase", surface_only=True, view="side"),
        synthesize(name="camera_movement", n_kicks=4, camera_motion=True, view="side"),
    ]
    for poses, labels, tracks in cases:
        write_case(labels["name"], poses, labels, tracks)
    (OUT / "README.md").write_text(
        "# Underwater Milestone 6 fixtures\n\n"
        "Synthetic smoothed-pose sequences with manually labeled kicks, breakout, and phase bounds.\n"
        "Generated by `scripts/make_underwater_fixtures.py`.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()

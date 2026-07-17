#!/usr/bin/env python3
"""Generate manually labeled turn / finish fixtures for Milestone 7."""

from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tests" / "fixtures" / "turn_finish"


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


def _pose(fi: int, t: float, mid_x: float, *, wall_x: float, phase: str, stroke_phase: float = 0.0) -> dict:
    sh_y = 200.0
    kps: list[dict] = []
    und = 8 * math.sin(2 * math.pi * stroke_phase)
    _set(kps, "left_shoulder", mid_x - 28, sh_y)
    _set(kps, "right_shoulder", mid_x + 28, sh_y)
    _set(kps, "left_hip", mid_x - 18, sh_y + 50)
    _set(kps, "right_hip", mid_x + 18, sh_y + 50)
    _set(kps, "nose", mid_x, sh_y - 28)

    if phase == "approach":
        fwd = 30 * math.cos(2 * math.pi * stroke_phase)
        _set(kps, "left_wrist", mid_x + fwd - 15, sh_y + 20 + und)
        _set(kps, "right_wrist", mid_x + fwd + 15, sh_y + 20 + und)
        _set(kps, "left_ankle", mid_x - 14, sh_y + 120)
        _set(kps, "right_ankle", mid_x + 14, sh_y + 120)
    elif phase == "contact":
        # hands/feet near wall
        _set(kps, "left_wrist", wall_x - 8, sh_y + 10)
        _set(kps, "right_wrist", wall_x - 6, sh_y + 12)
        _set(kps, "left_ankle", wall_x - 10, sh_y + 90)
        _set(kps, "right_ankle", wall_x - 8, sh_y + 92)
    elif phase == "push":
        _set(kps, "left_wrist", mid_x - 10, sh_y + 5)
        _set(kps, "right_wrist", mid_x + 10, sh_y + 5)
        _set(kps, "left_ankle", wall_x - 12, sh_y + 95)
        _set(kps, "right_ankle", wall_x - 10, sh_y + 97)
    else:  # underwater / leave
        wave = 12 * math.sin(2 * math.pi * stroke_phase)
        _set(kps, "left_wrist", mid_x - 8, sh_y + 8)
        _set(kps, "right_wrist", mid_x + 8, sh_y + 8)
        _set(kps, "left_ankle", mid_x - 12, sh_y + 110 + wave)
        _set(kps, "right_ankle", mid_x + 12, sh_y + 110 + wave)

    return {
        "video_id": "tf",
        "job_id": "fixture",
        "frame_number": fi,
        "timestamp_ms": t * 1000.0,
        "swimmer_track_id": "track-1",
        "crop_coordinates": [mid_x - 80, sh_y - 40, mid_x + 80, sh_y + 140],
        "keypoints": kps,
        "overall_pose_confidence": 0.85,
        "model_name": "synthetic-turn-finish",
        "model_version": "m7",
        "inference_resolution": [192, 256],
        "processing_duration_ms": 1.0,
        "usable": True,
        "unusable_reason": None,
        "quality_flags": [],
        "dataset": "smoothed",
    }


def make_turn_flip(*, name: str, wall_outside: bool = False, open_turn: bool = False) -> tuple[list[dict], dict]:
    fps = 30.0
    wall_x = 620.0 if not wall_outside else 800.0
    frame_width = 640
    # Approach from left toward wall
    approach_frames = 45
    contact_frame = 50
    foot_frame = 52
    push_frame = 55
    first_kick = 62
    breakout = 78
    first_surface = 80
    total = 95

    poses = []
    surface_entries = []
    kick_frames = []
    for fi in range(total):
        t = fi / fps
        if fi < contact_frame:
            # Approach: hip steadily closer to wall, unique minimum at contact_frame.
            mid = 200 + (wall_x - 38 - 200) * (fi / max(1, contact_frame))
            stroke_phase = (fi % 18) / 18.0
            if fi % 18 == 0:
                surface_entries.append(fi)
            poses.append(_pose(fi, t, mid, wall_x=wall_x, phase="approach", stroke_phase=stroke_phase))
        elif fi == contact_frame:
            mid = wall_x - 28
            poses.append(_pose(fi, t, mid, wall_x=wall_x, phase="contact"))
        elif fi < push_frame:
            # Hold near wall with feet planting (flip) before leaving.
            mid = wall_x - 32
            poses.append(_pose(fi, t, mid, wall_x=wall_x, phase="push" if fi >= foot_frame else "contact"))
        else:
            # leave wall
            mid = (wall_x - 32) - (fi - push_frame) * 4.5
            phase = (fi - push_frame) / 12.0
            poses.append(_pose(fi, t, mid, wall_x=wall_x, phase="leave", stroke_phase=phase))
            if fi in {first_kick, first_kick + 12}:
                kick_frames.append(fi)

    # Ensure labeled surface entries include final stroke boundary before wall
    final_stroke = max([e for e in surface_entries if e < contact_frame], default=contact_frame - 10)
    if final_stroke not in surface_entries:
        surface_entries.append(final_stroke)
    surface_entries = sorted(set(surface_entries + [first_surface]))

    labels = {
        "name": name,
        "kind": "turn",
        "fps": fps,
        "frame_width": frame_width,
        "wall_x": wall_x,
        "wall_outside": wall_outside,
        "turn_type": "open" if open_turn else "flip",
        "stroke": "butterfly",
        "view": "side",
        "manual_wall_line": {"x": wall_x, "confidence": 0.95, "supporting_frames": [contact_frame]},
        "wall_contact_frame": None if wall_outside else contact_frame,
        "push_off_frame": None if wall_outside else push_frame,
        "foot_placement_frame": None if (wall_outside or open_turn) else foot_frame,
        "breakout_frame": breakout,
        "first_underwater_kick_frame": first_kick,
        "first_surface_stroke_frame": first_surface,
        "final_stroke_before_wall_frame": final_stroke,
        "surface_stroke_entry_frames": surface_entries,
        "underwater_kick_frames": kick_frames or [first_kick],
        "notes": "Manually labeled synthetic flip/open turn sequence.",
    }
    return poses, labels


def make_finish(*, name: str, contact_not_visible: bool = False, clip_ends_early: bool = False) -> tuple[list[dict], dict]:
    fps = 30.0
    wall_x = 620.0
    frame_width = 640
    contact_frame = 70
    total = 60 if clip_ends_early else 85
    # Keep hips farther from the wall when contact is intentionally not visible.
    approach_end_x = wall_x - 140 if contact_not_visible else wall_x - 50
    poses = []
    surface_entries = []
    for fi in range(total):
        t = fi / fps
        mid = 180 + (min(fi, contact_frame) / contact_frame) * (approach_end_x - 180)
        stroke_phase = (fi % 16) / 16.0
        if fi % 16 == 0:
            surface_entries.append(fi)
        phase = "approach"
        if (not clip_ends_early) and fi == contact_frame and not contact_not_visible:
            phase = "contact"
            mid = wall_x - 30
        poses.append(_pose(fi, t, mid, wall_x=wall_x, phase=phase, stroke_phase=stroke_phase))

    # Labels use surface entries at or before the intended finish boundary.
    # For early-ending clips, use all available entries in the clip.
    contact_bound = contact_frame if not clip_ends_early else None
    pre_contact_entries = [
        e for e in surface_entries if contact_bound is None or e <= contact_bound
    ]
    final_cycle = pre_contact_entries[-2] if len(pre_contact_entries) >= 2 else None
    final_entry = pre_contact_entries[-1] if pre_contact_entries else None
    labels = {
        "name": name,
        "kind": "finish",
        "fps": fps,
        "frame_width": frame_width,
        "wall_x": wall_x,
        "stroke": "butterfly",
        "view": "side",
        "manual_wall_line": {"x": wall_x, "confidence": 0.95},
        "finish_contact_frame": None if (contact_not_visible or clip_ends_early) else contact_frame,
        "final_complete_stroke_cycle_frame": final_cycle,
        "final_hand_entry_frame": final_entry,
        "final_stroke_boundary_frame": final_entry,
        "surface_stroke_entry_frames": pre_contact_entries,
        "clip_ends_before_contact": clip_ends_early,
        "contact_not_visible": contact_not_visible,
        "notes": "Manually labeled synthetic finish sequence.",
    }
    return poses, labels


def write_case(name: str, poses: list[dict], labels: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.smoothed_pose.json").write_text(
        json.dumps(
            {"job_id": f"fixture-{name}", "video_id": name, "dataset": "smoothed", "poses": poses},
            separators=(",", ":"),
        ),
        encoding="utf-8",
    )
    (OUT / f"{name}.labels.json").write_text(json.dumps(labels, indent=2), encoding="utf-8")
    print(f"wrote {name} kind={labels['kind']}")


def main() -> None:
    cases = [
        make_turn_flip(name="turn_flip_clean"),
        make_turn_flip(name="turn_open", open_turn=True),
        make_turn_flip(name="turn_wall_outside", wall_outside=True),
        make_finish(name="finish_clean"),
        make_finish(name="finish_contact_not_visible", contact_not_visible=True),
        make_finish(name="finish_clip_ends_early", clip_ends_early=True),
    ]
    for poses, labels in cases:
        write_case(labels["name"], poses, labels)
    (OUT / "README.md").write_text(
        "# Turn / Finish Milestone 7 fixtures\n\n"
        "Synthetic smoothed-pose sequences with manually labeled wall-contact, push-off, "
        "breakout, finish-contact, and final-stroke boundaries.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()

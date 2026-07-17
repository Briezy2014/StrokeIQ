#!/usr/bin/env python3
"""Generate manually labeled synthetic butterfly pose fixtures for Milestone 5 tests."""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np

from app.domain.landmarks import COCO_WHOLEBODY_KEYPOINT_NAMES

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tests" / "fixtures" / "butterfly"

WRIST_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_wrist")
WRIST_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_wrist")
ELBOW_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_elbow")
ELBOW_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_elbow")
SH_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_shoulder")
SH_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_shoulder")
HIP_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_hip")
HIP_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_hip")
NOSE = COCO_WHOLEBODY_KEYPOINT_NAMES.index("nose")
KNEE_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_knee")
KNEE_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_knee")
ANKLE_L = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_ankle")
ANKLE_R = COCO_WHOLEBODY_KEYPOINT_NAMES.index("right_ankle")


# Compact fixtures: only core landmarks used by ButterflyAnalyzer (matched by name).
_CORE_IDXS = [
    NOSE,
    SH_L,
    SH_R,
    ELBOW_L,
    ELBOW_R,
    WRIST_L,
    WRIST_R,
    HIP_L,
    HIP_R,
    KNEE_L,
    KNEE_R,
    ANKLE_L,
    ANKLE_R,
]


def _empty_kps() -> list[dict]:
    return []


def _set(kps: list[dict], idx: int, x: float, y: float, conf: float = 0.9, flag: str = "valid") -> None:
    name = COCO_WHOLEBODY_KEYPOINT_NAMES[idx]
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
    n_cycles: int = 4,
    fps: float = 30.0,
    cycle_duration_s: float = 1.2,
    view: str = "side",
    breath_every: int = 1,
    missing_wrist_frames: set[int] | None = None,
    splash_entry_cycles: set[int] | None = None,
    partial_start: bool = False,
    partial_end: bool = False,
    variable_frame_rate: bool = False,
    diagonal: bool = False,
    duration_jitter_s: float = 0.0,
) -> tuple[list[dict], dict]:
    """
    Synthesize side-view-like butterfly kinematics.

    Hand entry at phase 0 of each cycle (forward wrist extrema).
    Pull through mid-cycle; recovery late cycle.
    Breath: nose elevation peak near phase ~0.35 when scheduled.
    """
    missing_wrist_frames = missing_wrist_frames or set()
    splash_entry_cycles = splash_entry_cycles or set()

    cycle_durs = []
    for i in range(n_cycles + (1 if partial_end else 0)):
        jitter = duration_jitter_s * math.sin(i * 1.7)
        cycle_durs.append(max(0.85, cycle_duration_s + jitter))

    # Build continuous timeline covering complete cycles (+ optional partials)
    # Entries at boundaries between cycles: n_cycles complete ⇒ n_cycles+1 entries
    n_entries = n_cycles + 1
    entry_times = [0.0]
    for d in cycle_durs[:n_cycles]:
        entry_times.append(entry_times[-1] + d)

    t_start = -0.4 * cycle_duration_s if partial_start else 0.0
    t_end = entry_times[-1] + (0.45 * cycle_duration_s if partial_end else 0.0)

    if variable_frame_rate:
        # Irregular dts around 1/fps
        times = [t_start]
        rng = np.random.default_rng(42)
        while times[-1] < t_end:
            times.append(times[-1] + float(rng.uniform(0.7, 1.4) / fps))
        times = [t for t in times if t <= t_end + 1e-9]
    else:
        n_frames = int(round((t_end - t_start) * fps)) + 1
        times = [t_start + i / fps for i in range(n_frames)]

    # Map entry times to nearest frame indices
    def nearest_frame(t: float) -> int:
        arr = np.asarray(times)
        return int(np.argmin(np.abs(arr - t)))

    labeled_entries = [nearest_frame(t) for t in entry_times]
    labeled_cycles = []
    for ci in range(n_cycles):
        labeled_cycles.append(
            {
                "cycle_index": ci,
                "start_frame": labeled_entries[ci],
                "end_frame": labeled_entries[ci + 1],
                "start_ms": times[labeled_entries[ci]] * 1000.0,
                "end_ms": times[labeled_entries[ci + 1]] * 1000.0,
                "duration_s": times[labeled_entries[ci + 1]] - times[labeled_entries[ci]],
            }
        )

    breath_frames = []
    poses = []
    shoulder_w = 60.0
    base_y = 220.0

    for fi, t in enumerate(times):
        # Locate phase within nearest cycle span
        if t <= entry_times[0]:
            # partial before first entry
            phase = 0.7 + 0.3 * ((t - t_start) / max(entry_times[0] - t_start, 1e-6))
            cyc_i = -1
            local_dur = cycle_duration_s
        elif t >= entry_times[-1]:
            phase = (t - entry_times[-1]) / max(cycle_duration_s, 1e-6)
            cyc_i = n_cycles
            local_dur = cycle_duration_s
        else:
            cyc_i = 0
            for i in range(len(entry_times) - 1):
                if entry_times[i] <= t <= entry_times[i + 1]:
                    cyc_i = i
                    local_dur = entry_times[i + 1] - entry_times[i]
                    phase = (t - entry_times[i]) / max(local_dur, 1e-6)
                    break

        # Forward projection oscillates: max at entry (phase 0), min mid-pull (~0.45)
        fwd = 40.0 * math.cos(2 * math.pi * phase)  # + at entry
        # Progress down the pool
        progress = 80.0 + (t - t_start) * 25.0
        if diagonal:
            progress *= 0.85
            fwd *= 0.75

        mid_x = progress
        # wrists: entry wide-ish, pull narrower under body
        width = shoulder_w * (1.15 - 0.35 * (0.5 - 0.5 * math.cos(2 * math.pi * phase)))
        lx = mid_x + fwd - 4
        rx = mid_x + fwd + 4
        # slight L/R timing offset (~20ms worth of phase)
        phase_r = phase + 0.02
        fwd_r = 40.0 * math.cos(2 * math.pi * phase_r)
        rx = mid_x + fwd_r + 4

        ly = base_y + 10 * math.sin(2 * math.pi * phase)
        ry = base_y + 10 * math.sin(2 * math.pi * phase_r)

        sh_y = base_y - 50 + 6 * math.sin(2 * math.pi * phase + 0.2)
        hip_y = base_y + 30 + 14 * math.sin(2 * math.pi * phase + math.pi)  # undulation opposite
        nose_y = sh_y - 28
        # Breathing: elevate nose every N cycles near phase 0.3-0.4
        if cyc_i >= 0 and cyc_i < n_cycles and (cyc_i % breath_every == 0) and 0.25 <= phase <= 0.45:
            nose_y = sh_y - 55
            if abs(phase - 0.35) < 0.03:
                breath_frames.append(fi)

        kps = _empty_kps()
        _set(kps, SH_L, mid_x - shoulder_w / 2, sh_y)
        _set(kps, SH_R, mid_x + shoulder_w / 2, sh_y)
        _set(kps, ELBOW_L, lx - 10, (ly + sh_y) / 2)
        _set(kps, ELBOW_R, rx + 10, (ry + sh_y) / 2)
        _set(kps, HIP_L, mid_x - 22, hip_y)
        _set(kps, HIP_R, mid_x + 22, hip_y)
        _set(kps, NOSE, mid_x + fwd * 0.15, nose_y)
        _set(kps, KNEE_L, mid_x - 18, hip_y + 40)
        _set(kps, KNEE_R, mid_x + 18, hip_y + 40)
        _set(kps, ANKLE_L, mid_x - 16, hip_y + 75)
        _set(kps, ANKLE_R, mid_x + 16, hip_y + 75)

        # Splash-obscured entry: drop wrists near entry of selected cycles
        splash = cyc_i in splash_entry_cycles and phase < 0.08
        if fi in missing_wrist_frames or splash:
            _set(kps, WRIST_L, lx, ly, conf=0.05, flag="low_confidence")
            _set(kps, WRIST_R, rx, ry, conf=0.05, flag="low_confidence")
        else:
            _set(kps, WRIST_L, lx - width / 2 + shoulder_w / 2, ly)
            _set(kps, WRIST_R, rx + width / 2 - shoulder_w / 2, ry)

        poses.append(
            {
                "video_id": name,
                "job_id": f"fixture-{name}",
                "frame_number": fi,
                "timestamp_ms": t * 1000.0,
                "swimmer_track_id": "track-1",
                "crop_coordinates": [0, 0, 640, 360],
                "keypoints": kps,
                "overall_pose_confidence": 0.85,
                "model_name": "synthetic-butterfly",
                "model_version": "m5",
                "inference_resolution": [192, 256],
                "processing_duration_ms": 1.0,
                "usable": True,
                "unusable_reason": None,
                "quality_flags": ["splash_obscured"] if splash else [],
                "dataset": "smoothed",
            }
        )

    labels = {
        "name": name,
        "view": view,
        "fps": fps,
        "n_cycles": n_cycles,
        "entry_frames": labeled_entries,
        "cycles": labeled_cycles,
        "breath_frames": sorted(set(breath_frames)),
        "breath_every": breath_every,
        "notes": "Manually defined synthetic butterfly kinematics with labeled entry boundaries.",
    }
    return poses, labels


def write_case(name: str, poses: list[dict], labels: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pose_path = OUT / f"{name}.smoothed_pose.json"
    label_path = OUT / f"{name}.labels.json"
    # Compact JSON (no indent) keeps fixture repo size manageable.
    pose_path.write_text(
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
    label_path.write_text(json.dumps(labels, indent=2), encoding="utf-8")
    print(f"wrote {pose_path.name} cycles={labels['n_cycles']} entries={labels['entry_frames']}")


def main() -> None:
    cases = []

    poses, labels = synthesize(name="clean_side_view", n_cycles=5, view="side")
    cases.append(("clean_side_view", poses, labels))

    poses, labels = synthesize(
        name="diagonal_view", n_cycles=4, view="diagonal_side", diagonal=True
    )
    cases.append(("diagonal_view", poses, labels))

    poses, labels = synthesize(
        name="breath_every_cycle", n_cycles=4, breath_every=1, view="side"
    )
    cases.append(("breath_every_cycle", poses, labels))

    poses, labels = synthesize(
        name="breath_every_second_cycle", n_cycles=4, breath_every=2, view="side"
    )
    cases.append(("breath_every_second_cycle", poses, labels))

    # missing wrists around mid clip
    base_poses, base_labels = synthesize(
        name="missing_wrist_frames",
        n_cycles=4,
        missing_wrist_frames=set(range(40, 48)),
    )
    base_labels["missing_wrist_frames"] = list(range(40, 48))
    cases.append(("missing_wrist_frames", base_poses, base_labels))

    poses, labels = synthesize(
        name="splash_obscured_entry",
        n_cycles=4,
        splash_entry_cycles={1, 2},
        view="side",
    )
    cases.append(("splash_obscured_entry", poses, labels))

    poses, labels = synthesize(
        name="partial_start", n_cycles=3, partial_start=True, view="side"
    )
    cases.append(("partial_start", poses, labels))

    poses, labels = synthesize(
        name="partial_end", n_cycles=3, partial_end=True, view="side"
    )
    cases.append(("partial_end", poses, labels))

    poses, labels = synthesize(name="fewer_than_two_cycles", n_cycles=1, view="side")
    cases.append(("fewer_than_two_cycles", poses, labels))

    poses, labels = synthesize(
        name="variable_frame_rate",
        n_cycles=4,
        variable_frame_rate=True,
        view="side",
    )
    cases.append(("variable_frame_rate", poses, labels))

    poses, labels = synthesize(
        name="timing_jitter",
        n_cycles=6,
        duration_jitter_s=0.12,
        view="side",
    )
    cases.append(("timing_jitter", poses, labels))

    for name, poses, labels in cases:
        write_case(name, poses, labels)

    # Index
    (OUT / "README.md").write_text(
        "# Butterfly Milestone 5 fixtures\n\n"
        "Synthetic smoothed-pose sequences with manually labeled cycle entry boundaries.\n"
        "Generated by `scripts/make_butterfly_fixtures.py`.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()

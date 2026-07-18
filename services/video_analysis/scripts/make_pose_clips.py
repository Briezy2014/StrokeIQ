#!/usr/bin/env python3
"""Build Stage B (5s) and Stage C (full) person clips for Milestone 3."""

from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
FIX = ROOT / "tests" / "fixtures"


def _load_base_frames() -> list[np.ndarray]:
    src = FIX / "person_clip.mp4"
    if not src.is_file():
        raise SystemExit("person_clip.mp4 missing; run scripts/make_m2_fixtures.py")
    cap = cv2.VideoCapture(str(src))
    frames = []
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        frames.append(frame)
    cap.release()
    if not frames:
        raise SystemExit("no frames in person_clip.mp4")
    return frames


def write_looped(path: Path, frames: list[np.ndarray], seconds: float, fps: int = 24) -> None:
    h, w = frames[0].shape[:2]
    writer = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
    need = int(seconds * fps)
    for i in range(need):
        # gentle horizontal shift while looping source frames
        base = frames[i % len(frames)].copy()
        shift = (i * 2) % 40
        canvas = np.full_like(base, 114)
        canvas[:, shift:] = base[:, : w - shift]
        writer.write(canvas)
    writer.release()
    print("wrote", path, "frames", need)


def main() -> None:
    frames = _load_base_frames()
    write_looped(FIX / "pose_stage_b_5s.mp4", frames, seconds=5.0)
    write_looped(FIX / "pose_stage_c_full.mp4", frames, seconds=8.0)
    # Still image for Stage A
    still = FIX / "pose_stage_a_still.jpg"
    cv2.imwrite(str(still), frames[0])
    print("wrote", still)


if __name__ == "__main__":
    main()

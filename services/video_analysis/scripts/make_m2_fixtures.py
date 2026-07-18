#!/usr/bin/env python3
"""Generate synthetic multi-swimmer clips + a short real-person clip for M2 tests."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
FIX = ROOT / "tests" / "fixtures"
FIX.mkdir(parents=True, exist_ok=True)


def write_mp4(path: Path, frames: list[np.ndarray], fps: int = 30) -> None:
    h, w = frames[0].shape[:2]
    writer = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
    for frame in frames:
        writer.write(frame)
    writer.release()


def synthetic_multi_swimmer() -> None:
    """Two moving blobs in neighboring lanes + optional splash occlusion."""
    w, h, n = 640, 360, 60
    frames = []
    script: dict[str, list] = {}
    for i in range(n):
        frame = np.full((h, w, 3), (90, 60, 20), dtype=np.uint8)  # pool-ish
        # lane lines
        for y in (90, 180, 270):
            cv2.line(frame, (0, y), (w, y), (200, 200, 200), 1)

        # swimmer A (target-ish, left lane)
        ax = 40 + i * 8
        ay = 120
        if 25 <= i <= 32:
            # splash occlusion
            cv2.ellipse(frame, (ax, ay), (70, 40), 0, 0, 360, (240, 240, 240), -1)
            boxes = []
        else:
            cv2.ellipse(frame, (ax, ay), (40, 18), 0, 0, 360, (30, 30, 200), -1)
            boxes = [([ax - 40, ay - 18, ax + 40, ay + 18], 0.9)]

        # swimmer B neighboring lane
        bx = 80 + i * 7
        by = 220
        cv2.ellipse(frame, (bx, by), (36, 16), 0, 0, 360, (200, 40, 40), -1)
        boxes.append(([bx - 36, by - 16, bx + 36, by + 16], 0.85))

        script[str(i)] = boxes
        frames.append(frame)

    path = FIX / "multi_swimmer_synth.mp4"
    write_mp4(path, frames)
    (FIX / "multi_swimmer_script.json").write_text(json.dumps(script, indent=2))
    print("wrote", path)


def synthetic_reenter() -> None:
    w, h, n = 480, 270, 45
    frames = []
    script: dict[str, list] = {}
    for i in range(n):
        frame = np.full((h, w, 3), (80, 50, 15), dtype=np.uint8)
        if i < 12:
            x = 60 + i * 10
            y = 130
            cv2.ellipse(frame, (x, y), (35, 15), 0, 0, 360, (20, 20, 220), -1)
            script[str(i)] = [([x - 35, y - 15, x + 35, y + 15], 0.92)]
        elif i < 24:
            # left frame — no detection
            script[str(i)] = []
        else:
            x = 40 + (i - 24) * 10
            y = 140
            cv2.ellipse(frame, (x, y), (35, 15), 0, 0, 360, (20, 20, 220), -1)
            script[str(i)] = [([x - 35, y - 15, x + 35, y + 15], 0.9)]
        frames.append(frame)
    write_mp4(FIX / "reenter_synth.mp4", frames)
    (FIX / "reenter_script.json").write_text(json.dumps(script, indent=2))
    print("wrote reenter_synth.mp4")


def person_clip() -> None:
    img_path = FIX / "person_source.jpg"
    if not img_path.is_file():
        url = "https://raw.githubusercontent.com/open-mmlab/mmdetection/main/demo/demo.jpg"
        urllib.request.urlretrieve(url, img_path)
    img = cv2.imread(str(img_path))
    if img is None:
        raise RuntimeError("failed to load person source image")
    h, w = img.shape[:2]
    frames = []
    for i in range(36):
        # gentle pan/crop to create motion
        shift = i * 2
        canvas = np.full_like(img, 114)
        x0 = min(shift, max(0, w - 10))
        piece = img[:, x0:]
        canvas[:, : piece.shape[1]] = piece
        frames.append(canvas)
    write_mp4(FIX / "person_clip.mp4", frames, fps=24)
    print("wrote person_clip.mp4")


def rotated_person() -> None:
    src = FIX / "person_clip.mp4"
    if not src.is_file():
        person_clip()
    cap = cv2.VideoCapture(str(src))
    frames = []
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        frames.append(cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE))
    cap.release()
    if frames:
        write_mp4(FIX / "person_clip_rotated.mp4", frames, fps=24)
        print("wrote person_clip_rotated.mp4")


if __name__ == "__main__":
    synthetic_multi_swimmer()
    synthetic_reenter()
    person_clip()
    rotated_person()

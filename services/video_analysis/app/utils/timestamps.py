"""Timestamp and frame-number conversion helpers."""

from __future__ import annotations


def ms_to_frame(timestamp_ms: float, fps: float) -> int:
    if fps <= 0:
        raise ValueError("fps must be positive")
    return int(round((timestamp_ms / 1000.0) * fps))


def frame_to_ms(frame_number: int, fps: float) -> float:
    if fps <= 0:
        raise ValueError("fps must be positive")
    if frame_number < 0:
        raise ValueError("frame_number must be non-negative")
    return (frame_number / fps) * 1000.0


def seconds_to_ms(seconds: float) -> int:
    return int(round(seconds * 1000.0))

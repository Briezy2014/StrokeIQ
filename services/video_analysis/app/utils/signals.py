"""Signal processing helpers (shared utilities; pose smoothing lives in pose_smoother)."""

from __future__ import annotations


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))

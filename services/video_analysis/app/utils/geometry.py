"""Geometry helpers (angles, distances) — expanded in later milestones."""

from __future__ import annotations

import math


def angle_degrees(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float]) -> float:
    """Return interior angle ABC in degrees."""
    bax, bay = a[0] - b[0], a[1] - b[1]
    bcx, bcy = c[0] - b[0], c[1] - b[1]
    dot = bax * bcx + bay * bcy
    norm = math.hypot(bax, bay) * math.hypot(bcx, bcy)
    if norm == 0:
        return float("nan")
    cos_angle = max(-1.0, min(1.0, dot / norm))
    return math.degrees(math.acos(cos_angle))

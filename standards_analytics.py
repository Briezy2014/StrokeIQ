"""Shared USA Swimming motivational standards analytics."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

LEVELS = ("B", "BB", "A", "AA", "AAA", "AAAA")


@dataclass(frozen=True)
class StandardComparison:
    current_level: str | None
    next_level: str | None
    time_to_next_standard: float | None
    percent_progress: float | None


def _level_time(standard: dict[str, Any], level: str) -> float:
    return float(standard[f"{level.lower()}_time"])


def best_standard_achieved(swim_time_seconds: float, standard: dict[str, Any]) -> str | None:
    best: str | None = None
    for level in LEVELS:
        if swim_time_seconds <= _level_time(standard, level):
            best = level
    return best


def current_standard(swim_time_seconds: float, standard: dict[str, Any]) -> str | None:
    return best_standard_achieved(swim_time_seconds, standard)


def next_standard(swim_time_seconds: float, standard: dict[str, Any]) -> str | None:
    achieved = current_standard(swim_time_seconds, standard)
    if achieved is None:
        return "B"
    index = LEVELS.index(achieved)
    if index + 1 >= len(LEVELS):
        return None
    return LEVELS[index + 1]


def time_to_next_standard(swim_time_seconds: float, standard: dict[str, Any]) -> float | None:
    upcoming = next_standard(swim_time_seconds, standard)
    if upcoming is None:
        return None
    return round(swim_time_seconds - _level_time(standard, upcoming), 2)


def percent_progress(swim_time_seconds: float, standard: dict[str, Any]) -> float | None:
    achieved = current_standard(swim_time_seconds, standard)
    upcoming = next_standard(swim_time_seconds, standard)
    if upcoming is None:
        return 100.0 if achieved == "AAAA" else None

    next_cutoff = _level_time(standard, upcoming)
    start_cutoff = _level_time(standard, achieved) if achieved else _level_time(standard, "B") * 1.08
    span = start_cutoff - next_cutoff
    if span <= 0:
        return None
    raw = ((start_cutoff - swim_time_seconds) / span) * 100
    return max(0.0, min(100.0, raw))


def compare(swim_time_seconds: float, standard: dict[str, Any]) -> StandardComparison:
    return StandardComparison(
        current_level=current_standard(swim_time_seconds, standard),
        next_level=next_standard(swim_time_seconds, standard),
        time_to_next_standard=time_to_next_standard(swim_time_seconds, standard),
        percent_progress=percent_progress(swim_time_seconds, standard),
    )


def coach_insight(event: str, swim_time_seconds: float, standard: dict[str, Any]) -> str:
    result = compare(swim_time_seconds, standard)
    current = result.current_level or "Below B"
    if result.next_level is None or result.time_to_next_standard is None:
        return f"You are currently {current} in {event}."

    gap = result.time_to_next_standard
    gap_text = (
        f"You are inside the {result.next_level} cutoff."
        if gap <= 0
        else f"You are {gap:.2f} seconds from {result.next_level}."
    )

    return (
        f"You are currently {current} in {event}. {gap_text} "
        "Based on today's race, improving your breakout and maintaining "
        f"stroke tempo over the final 25 meters is likely to provide the largest "
        f"improvement toward {result.next_level}."
    )

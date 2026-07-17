"""Shared types for butterfly surface-stroke analysis."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal

ConfidenceLabel = Literal["high", "moderate", "low", "unavailable"]
Classification = Literal["measured", "estimated", "observational", "unavailable"]
EventType = Literal["cycle_start", "cycle_end", "hand_entry", "breath_estimate"]


def confidence_label(score: float | None) -> ConfidenceLabel:
    if score is None:
        return "unavailable"
    if score >= 0.75:
        return "high"
    if score >= 0.5:
        return "moderate"
    if score > 0:
        return "low"
    return "unavailable"


@dataclass
class MetricValue:
    name: str
    display_name: str
    value: float | int | None
    unit: str | None
    confidence: float
    confidence_label: ConfidenceLabel
    classification: Classification
    method: str
    supporting_timestamps_ms: list[float] = field(default_factory=list)
    supporting_frame_numbers: list[int] = field(default_factory=list)
    quality_flags: list[str] = field(default_factory=list)
    unavailable_reason: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def unavailable(
        cls,
        *,
        name: str,
        display_name: str,
        unit: str | None,
        method: str,
        reason: str,
        quality_flags: list[str] | None = None,
    ) -> MetricValue:
        return cls(
            name=name,
            display_name=display_name,
            value=None,
            unit=unit,
            confidence=0.0,
            confidence_label="unavailable",
            classification="unavailable",
            method=method,
            quality_flags=quality_flags or [],
            unavailable_reason=reason,
        )


@dataclass
class StrokeEvent:
    event_type: EventType
    timestamp_ms: float
    frame_number: int
    confidence: float
    confidence_label: ConfidenceLabel
    side: str | None = None  # left | right | both
    cycle_index: int | None = None
    quality_flags: list[str] = field(default_factory=list)
    notes: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class CycleBoundary:
    cycle_index: int
    start_frame: int
    end_frame: int
    start_ms: float
    end_ms: float
    duration_s: float
    entry_frame: int
    next_entry_frame: int
    pull_initiation_frame: int | None
    recovery_frame: int | None
    left_entry_frame: int | None
    right_entry_frame: int | None
    complete: bool
    confidence: float
    quality_flags: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

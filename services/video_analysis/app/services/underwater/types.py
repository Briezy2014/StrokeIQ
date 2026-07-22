"""Types for underwater-phase / dolphin-kick / breakout analysis (Milestone 6)."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal

from app.services.butterfly.types import (  # reuse shared metric schema
    Classification,
    ConfidenceLabel,
    MetricValue,
    confidence_label,
)

UnderwaterEventType = Literal[
    "water_entry",
    "underwater_start",
    "dolphin_kick",
    "breakout",
    "first_surface_stroke",
    "underwater_end",
]


@dataclass
class UnderwaterEvent:
    event_type: UnderwaterEventType
    timestamp_ms: float
    frame_number: int
    confidence: float
    confidence_label: ConfidenceLabel
    method: str
    supporting_landmarks: list[str] = field(default_factory=list)
    quality_flags: list[str] = field(default_factory=list)
    notes: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class UnderwaterPhase:
    start_frame: int
    end_frame: int
    start_ms: float
    end_ms: float
    duration_s: float
    complete: bool
    confidence: float
    quality_flags: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


__all__ = [
    "Classification",
    "ConfidenceLabel",
    "MetricValue",
    "UnderwaterEvent",
    "UnderwaterEventType",
    "UnderwaterPhase",
    "confidence_label",
]

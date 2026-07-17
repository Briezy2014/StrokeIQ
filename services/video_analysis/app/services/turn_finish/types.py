"""Shared types for turn / finish event framework (Milestone 7)."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal

from app.services.butterfly.types import (
    Classification,
    ConfidenceLabel,
    MetricValue,
    confidence_label,
)

WallMethod = Literal[
    "manual_wall_line",
    "auto_edge",
    "pool_geometry",
    "lane_line_termination",
    "starting_block",
    "trajectory_asymptote",
    "unavailable",
]

TurnEventType = Literal[
    "approach_begins",
    "final_stroke_before_wall",
    "turn_initiation",
    "wall_contact",
    "foot_placement",
    "push_off",
    "first_underwater_kick",
    "breakout",
    "first_surface_stroke",
]

FinishEventType = Literal[
    "final_complete_stroke_cycle",
    "final_hand_entry",
    "final_reach",
    "glide_into_wall",
    "wall_contact",
    "shortened_or_added_stroke_estimate",
    "head_position_observation",
]


@dataclass
class WallCalibration:
    wall_x: float | None
    wall_side: Literal["left", "right", "unknown"]
    method: WallMethod
    confidence: float
    confidence_label: ConfidenceLabel
    frame_width: int | None = None
    meters_per_pixel: float | None = None
    quality_flags: list[str] = field(default_factory=list)
    limitations: list[str] = field(default_factory=list)
    supporting_frames: list[int] = field(default_factory=list)
    notes: str | None = None

    @property
    def wall_in_frame(self) -> bool:
        if self.wall_x is None or self.frame_width is None:
            return False
        return 0.0 <= float(self.wall_x) <= float(self.frame_width)

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        d["wall_in_frame"] = self.wall_in_frame
        return d


@dataclass
class RaceEvent:
    event_type: str
    timestamp_ms: float | None
    frame_number: int | None
    confidence: float
    confidence_label: ConfidenceLabel
    method: str
    supporting_frames: list[int] = field(default_factory=list)
    supporting_timestamps_ms: list[float] = field(default_factory=list)
    quality_flags: list[str] = field(default_factory=list)
    limitations: list[str] = field(default_factory=list)
    unavailable_reason: str | None = None
    value: float | int | None = None
    unit: str | None = None
    supporting_landmarks: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def unavailable(
        cls,
        *,
        event_type: str,
        method: str,
        reason: str,
        quality_flags: list[str] | None = None,
        limitations: list[str] | None = None,
    ) -> RaceEvent:
        return cls(
            event_type=event_type,
            timestamp_ms=None,
            frame_number=None,
            confidence=0.0,
            confidence_label="unavailable",
            method=method,
            quality_flags=quality_flags or [],
            limitations=limitations or [reason],
            unavailable_reason=reason,
        )


__all__ = [
    "Classification",
    "ConfidenceLabel",
    "FinishEventType",
    "MetricValue",
    "RaceEvent",
    "TurnEventType",
    "WallCalibration",
    "WallMethod",
    "confidence_label",
]

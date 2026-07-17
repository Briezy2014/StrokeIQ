"""Metric schema reserved for later milestones."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


ConfidenceLabel = Literal["high", "moderate", "low", "unavailable"]
Classification = Literal["measured", "estimated", "observational", "unavailable"]


class MetricResult(BaseModel):
    name: str
    display_name: str
    value: float | int | None
    unit: str | None
    confidence: float = Field(ge=0.0, le=1.0)
    confidence_label: ConfidenceLabel
    classification: Classification
    method: str
    start_ms: int | None = None
    end_ms: int | None = None
    supporting_frames: list[int] = Field(default_factory=list)
    quality_flags: list[str] = Field(default_factory=list)
    comparison: Any | None = None
    unavailable_reason: str | None = None

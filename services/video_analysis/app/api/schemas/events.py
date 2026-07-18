"""Event/phase schema reserved for later milestones."""

from __future__ import annotations

from pydantic import BaseModel, Field


class PhaseEvent(BaseModel):
    name: str
    start_ms: int
    end_ms: int
    start_frame: int | None = None
    end_frame: int | None = None
    confidence: float = Field(ge=0.0, le=1.0)
    editable: bool = True
    quality_flags: list[str] = Field(default_factory=list)
    evidence_frames: list[int] = Field(default_factory=list)

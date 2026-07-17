"""Request schemas for the analysis API."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


StrokeHint = Literal[
    "butterfly",
    "freestyle",
    "backstroke",
    "breaststroke",
    "im",
    "unknown",
]

ViewHint = Literal[
    "side",
    "diagonal_side",
    "end",
    "deck",
    "underwater_side",
    "underwater_front",
    "mixed",
    "unknown",
]


class AthleteRef(BaseModel):
    swimmer_key: str
    display_name: str | None = None
    age_group: str | None = None


class EventRef(BaseModel):
    stroke: StrokeHint = "unknown"
    distance_m: int | None = None
    course: str | None = None
    title: str | None = None
    notes: str | None = None


class AnalysisOptions(BaseModel):
    target_track_id: str | None = None
    view_hint: ViewHint = "unknown"
    generate_overlay: bool = False
    generate_gemini_report: bool = False


class CreateAnalysisRequest(BaseModel):
    """Create a job from a local path (M1) or Supabase reference (later)."""

    video_id: str
    storage_bucket: str | None = "swim-videos"
    storage_path: str | None = None
    local_path: str | None = Field(
        default=None,
        description="Absolute or service-relative path for Milestone 1 local validation.",
    )
    athlete: AthleteRef | None = None
    event: EventRef | None = None
    options: AnalysisOptions = Field(default_factory=AnalysisOptions)

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

TargetSelectionMode = Literal[
    "automatic",
    "track_id",
    "normalized_coordinate",
    "bounding_box",
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
    target_selection_mode: TargetSelectionMode = "automatic"
    target_track_id: str | None = None
    target_normalized_xy: dict[str, float] | None = Field(
        default=None,
        description="Normalized screen point {x,y} in 0..1 for target selection",
    )
    target_bbox: list[float] | None = Field(
        default=None,
        description="User-selected bbox [x1,y1,x2,y2] in pixel coordinates",
    )
    view_hint: ViewHint = "unknown"
    generate_overlay: bool = True
    generate_gemini_report: bool = False
    # Milestone 3 — run exactly one pose stage when enabled (no auto-advance).
    run_pose_stage: bool = False
    pose_stage: Literal["A", "B", "C"] | None = None
    pose_source_path: str | None = None
    write_pose_acceptance: bool = True
    # Milestone 5 — butterfly surface analysis (requires smoothed poses)
    run_butterfly_analysis: bool = False
    pool_distance_calibrated: bool = False


class CreateAnalysisRequest(BaseModel):
    """Create a job from a local path (M1/M2) or Supabase reference (later)."""

    video_id: str
    storage_bucket: str | None = "swim-videos"
    storage_path: str | None = None
    local_path: str | None = Field(
        default=None,
        description="Absolute or service-relative path for local validation/detection.",
    )
    athlete: AthleteRef | None = None
    event: EventRef | None = None
    options: AnalysisOptions = Field(default_factory=AnalysisOptions)

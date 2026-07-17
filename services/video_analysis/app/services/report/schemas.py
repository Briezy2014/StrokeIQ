"""Pydantic schemas for Gemini coaching-report prompt + response (Milestone 8)."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator


PROMPT_VERSION = "elote-gemini-coach-v1"
REPORT_SCHEMA_VERSION = "coaching_report_v1"
DEFAULT_MODEL_NAME = "gemini-2.5-flash"

ConfidenceBand = Literal["high", "moderate", "low", "unavailable"]


class DeterministicMetricRef(BaseModel):
    """Validated metric snapshot sent to Gemini (never raw video)."""

    metric_id: str
    name: str
    display_name: str | None = None
    value: float | int | None = None
    unit: str | None = None
    confidence: float = 0.0
    confidence_label: str = "unavailable"
    classification: str | None = None
    method: str | None = None
    unavailable_reason: str | None = None
    quality_flags: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)
    supporting_frame_numbers: list[int] = Field(default_factory=list)
    supporting_timestamps_ms: list[float] = Field(default_factory=list)


class DeterministicEventRef(BaseModel):
    event_id: str
    event_type: str
    timestamp_ms: float | None = None
    frame_number: int | None = None
    confidence: float = 0.0
    confidence_label: str = "unavailable"
    method: str | None = None
    unavailable_reason: str | None = None
    quality_flags: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)
    supporting_frames: list[int] = Field(default_factory=list)
    supporting_timestamps_ms: list[float] = Field(default_factory=list)


class EvidenceFrameRef(BaseModel):
    frame_number: int | None = None
    path: str | None = None
    label: str | None = None
    metric_ids: list[str] = Field(default_factory=list)
    event_ids: list[str] = Field(default_factory=list)


class ReportContext(BaseModel):
    """Structured context Gemini is allowed to see."""

    job_id: str
    video_id: str
    stroke_type: str = "unknown"
    course: str | None = None
    race_distance_m: int | None = None
    athlete_age_group: str | None = None
    athlete_display_name: str | None = None
    analysis_limitations: list[str] = Field(default_factory=list)
    metrics: list[DeterministicMetricRef] = Field(default_factory=list)
    events: list[DeterministicEventRef] = Field(default_factory=list)
    evidence_frames: list[EvidenceFrameRef] = Field(default_factory=list)
    previous_athlete_results: list[dict[str, Any]] = Field(default_factory=list)
    approved_standards: list[dict[str, Any]] = Field(default_factory=list)
    authorize_age_group: bool = False
    authorize_previous_results: bool = False

    def available_metric_ids(self) -> set[str]:
        return {
            m.metric_id
            for m in self.metrics
            if m.value is not None and (m.unavailable_reason is None)
        }

    def all_metric_ids(self) -> set[str]:
        return {m.metric_id for m in self.metrics}

    def available_event_ids(self) -> set[str]:
        return {
            e.event_id
            for e in self.events
            if e.frame_number is not None and e.unavailable_reason is None
        }

    def all_event_ids(self) -> set[str]:
        return {e.event_id for e in self.events}

    def metric_by_id(self) -> dict[str, DeterministicMetricRef]:
        return {m.metric_id: m for m in self.metrics}

    def event_by_id(self) -> dict[str, DeterministicEventRef]:
        return {e.event_id: e for e in self.events}


class CoachingObservation(BaseModel):
    """One coaching claim that must cite deterministic evidence IDs."""

    text: str = Field(min_length=8, max_length=600)
    confidence_band: ConfidenceBand
    metric_ids: list[str] = Field(default_factory=list)
    event_ids: list[str] = Field(default_factory=list)

    @field_validator("text")
    @classmethod
    def _strip(cls, v: str) -> str:
        return v.strip()


class PriorityImprovement(BaseModel):
    observation: CoachingObservation
    drills: list[str] = Field(min_length=1, max_length=2)


class CoachingReportBody(BaseModel):
    """Structured JSON body required from Gemini (validated by Pydantic)."""

    summary: str = Field(min_length=20, max_length=1200)
    strengths: list[CoachingObservation] = Field(min_length=1, max_length=3)
    priority_improvements: list[PriorityImprovement] = Field(min_length=0, max_length=3)
    supporting_evidence: list[str] = Field(default_factory=list, max_length=8)
    race_recommendations: list[str] = Field(default_factory=list, max_length=5)
    limitations: list[str] = Field(min_length=1, max_length=12)
    confidence_statement: str = Field(min_length=20, max_length=800)
    disclaimer: str = Field(min_length=20, max_length=800)

    @field_validator("summary", "confidence_statement", "disclaimer")
    @classmethod
    def _strip_text(cls, v: str) -> str:
        return v.strip()


class StoredCoachingReport(BaseModel):
    """Persisted report envelope with generation provenance."""

    schema_version: str = REPORT_SCHEMA_VERSION
    prompt_version: str = PROMPT_VERSION
    model_name: str
    model_version: str
    generation_timestamp: datetime
    job_id: str
    video_id: str
    status: Literal["validated", "failed", "skipped"] = "validated"
    report: CoachingReportBody | None = None
    referenced_metric_ids: list[str] = Field(default_factory=list)
    referenced_event_ids: list[str] = Field(default_factory=list)
    validation_errors: list[str] = Field(default_factory=list)
    failure_reason: str | None = None
    failure_code: str | None = None
    regenerate_attempts: int = 0


class ReportGenerationResult(BaseModel):
    """Pipeline result: deterministic metrics always survive Gemini failure."""

    deterministic_metrics: list[dict[str, Any]] = Field(default_factory=list)
    deterministic_events: list[dict[str, Any]] = Field(default_factory=list)
    report: StoredCoachingReport | None = None
    artifact_paths: dict[str, str] = Field(default_factory=dict)
    limitations: list[str] = Field(default_factory=list)
    gemini_succeeded: bool = False

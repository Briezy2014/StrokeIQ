"""Response schemas for the analysis API."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    queued = "queued"
    downloading = "downloading"
    validating = "validating"
    preprocessing = "preprocessing"
    detecting_swimmer = "detecting_swimmer"
    estimating_pose = "estimating_pose"
    detecting_events = "detecting_events"
    calculating_metrics = "calculating_metrics"
    validating_results = "validating_results"
    generating_report = "generating_report"
    completed = "completed"
    completed_with_limitations = "completed_with_limitations"
    failed = "failed"
    cancelled = "cancelled"


class HealthResponse(BaseModel):
    status: str
    engine_version: str
    ffmpeg_available: bool
    ffprobe_available: bool
    ffmpeg_path: str
    ffprobe_path: str
    # Booleans only — never expose secret values.
    supabase_url_configured: bool = False
    supabase_anon_configured: bool = False
    supabase_service_role_configured: bool = False
    storage_download_configured: bool = False
    gemini_api_key_configured: bool = False


class JobError(BaseModel):
    error_code: str
    message: str
    stage: str
    job_id: str
    retriable: bool = False


class JobStatusResponse(BaseModel):
    job_id: str
    status: JobStatus
    progress: float = Field(ge=0.0, le=1.0)
    stage: str
    engine_version: str
    video_id: str
    error: JobError | None = None
    retry_count: int = 0
    created_at: datetime
    updated_at: datetime


class CreateAnalysisResponse(BaseModel):
    job_id: str
    status: JobStatus
    stage: str
    video_id: str
    engine_version: str
    created_at: datetime


class VideoMetadataResult(BaseModel):
    duration_ms: int
    fps: float
    width: int
    height: int
    frame_count: int | None = None
    codec: str | None = None
    mime_type: str | None = None
    rotation: int | None = 0
    file_size_bytes: int
    original_path: str
    normalized_path: str | None = None
    proxy_path: str | None = None
    quality_flags: list[str] = Field(default_factory=list)
    view: str = "unknown"
    quality_score: float | None = None


class AnalysisResultsResponse(BaseModel):
    """Milestone 2 returns metadata + tracking; no coaching report / pose metrics."""

    job_id: str
    status: JobStatus
    engine_version: str
    video_id: str
    video: VideoMetadataResult | None = None
    athlete: dict[str, Any] | None = None
    stroke: dict[str, Any] | None = None
    tracking: dict[str, Any] | None = None
    phases: list[Any] = Field(default_factory=list)
    metrics: list[Any] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)
    evidence_frames: list[Any] = Field(default_factory=list)
    model_versions: dict[str, str] = Field(default_factory=dict)
    report: dict[str, Any] | None = None
    error: JobError | None = None
    created_at: datetime
    metadata_artifact_path: str | None = None


class CancelResponse(BaseModel):
    job_id: str
    status: JobStatus
    message: str


class RetryResponse(BaseModel):
    job_id: str
    status: JobStatus
    stage: str
    message: str

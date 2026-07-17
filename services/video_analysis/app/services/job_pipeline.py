"""Milestone 1 pipeline: validate → preprocess → complete (metadata only)."""

from __future__ import annotations

from pathlib import Path

from app.api.schemas.responses import JobStatus
from app.config import Settings
from app.domain.jobs import AnalysisJob
from app.services.result_store import ResultStore
from app.services.video_preprocessor import preprocess_video
from app.services.video_validator import VideoValidationError, validate_video
from app.utils.logging import get_logger, log_exception, log_stage

logger = get_logger("video_analysis.pipeline")


def resolve_local_path(job: AnalysisJob) -> Path:
    if job.local_path:
        return Path(job.local_path).expanduser().resolve()
    raise VideoValidationError(
        "LOCAL_PATH_REQUIRED",
        "Milestone 1 requires local_path. Supabase download lands in a later milestone.",
        retriable=False,
    )


def run_milestone1_pipeline(
    job: AnalysisJob,
    *,
    settings: Settings,
    store: ResultStore,
) -> AnalysisJob:
    video_id = job.video_id
    job_id = job.job_id

    if job.cancelled:
        job.mark_failed(
            error_code="CANCELLED",
            message="Job was cancelled before processing started",
            stage=JobStatus.queued.value,
            retriable=False,
        )
        store.save(job)
        return job

    try:
        job.transition(JobStatus.validating, progress=0.1)
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Starting video validation",
        )

        path = resolve_local_path(job)
        validated = validate_video(path, settings)

        if job.cancelled:
            job.mark_failed(
                error_code="CANCELLED",
                message="Job was cancelled during validation",
                stage=JobStatus.validating.value,
                retriable=False,
            )
            store.save(job)
            return job

        job.transition(JobStatus.preprocessing, progress=0.55)
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Validation passed; writing artifacts",
        )

        options = (job.request_payload or {}).get("options") or {}
        view_hint = options.get("view_hint") or "unknown"
        result = preprocess_video(
            settings=settings,
            job_id=job_id,
            video_id=video_id,
            validated=validated,
            view_hint=view_hint,
        )

        job.metadata = result.metadata
        job.metadata_artifact_path = result.metadata_path
        job.limitations = list(result.limitations)

        if job.limitations:
            job.transition(JobStatus.completed_with_limitations, progress=1.0)
        else:
            job.transition(JobStatus.completed, progress=1.0)
        job.error = None
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Milestone 1 pipeline completed",
            metadata_path=result.metadata_path,
        )
        return job

    except VideoValidationError as exc:
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code=exc.error_code,
            message=exc.message,
            stage=job.stage,
            retriable=exc.retriable,
        )
        store.save(job)
        return job
    except Exception as exc:  # noqa: BLE001 — must log and fail the job, not swallow
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code="INTERNAL_ERROR",
            message=str(exc),
            stage=job.stage,
            retriable=True,
        )
        store.save(job)
        return job

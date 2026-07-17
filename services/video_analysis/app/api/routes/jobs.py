"""Cancel and retry routes."""

from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, HTTPException, Request

from app.api.schemas.responses import CancelResponse, JobStatus, RetryResponse
from app.services.job_pipeline import run_analysis_pipeline
from app.utils.logging import get_logger, log_stage

router = APIRouter(prefix="/v1/analyses", tags=["jobs"])
logger = get_logger("video_analysis.jobs")


@router.post("/{job_id}/cancel", response_model=CancelResponse)
def cancel_job(job_id: str, request: Request) -> CancelResponse:
    store = request.app.state.store
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    }:
        raise HTTPException(
            status_code=409,
            detail={
                "error_code": "NOT_CANCELLABLE",
                "message": f"Job already finished with status {job.status.value}",
                "job_id": job_id,
            },
        )

    job.cancelled = True
    # If still queued / early, mark failed immediately for observability.
    if job.status in {JobStatus.queued, JobStatus.validating, JobStatus.preprocessing}:
        job.mark_failed(
            error_code="CANCELLED",
            message="Job cancelled by client",
            stage=job.stage,
            retriable=False,
        )
    store.save(job)
    log_stage(
        logger,
        stage=job.stage,
        job_id=job.job_id,
        video_id=job.video_id,
        message="Job cancelled",
    )
    return CancelResponse(
        job_id=job.job_id,
        status=job.status,
        message="Job cancelled",
    )


@router.post("/{job_id}/retry", response_model=RetryResponse)
def retry_job(
    job_id: str,
    background_tasks: BackgroundTasks,
    request: Request,
) -> RetryResponse:
    settings = request.app.state.settings
    store = request.app.state.store
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != JobStatus.failed:
        raise HTTPException(
            status_code=409,
            detail={
                "error_code": "NOT_RETRIABLE",
                "message": "Only failed jobs can be retried in Milestone 1",
                "job_id": job_id,
            },
        )

    if job.error and not job.error.retriable:
        # Still allow explicit retry from failed validation of missing file after path fix,
        # but document non-retriable codes.
        if job.error.error_code in {
            "UNSUPPORTED_CODEC",
            "NO_VIDEO_STREAM",
            "EMPTY_FILE",
            "VIDEO_TOO_LARGE",
            "RESOLUTION_TOO_LOW",
            "FPS_TOO_LOW",
            "DURATION_TOO_SHORT",
            "CANCELLED",
        }:
            raise HTTPException(
                status_code=409,
                detail={
                    "error_code": "NOT_RETRIABLE",
                    "message": f"Error {job.error.error_code} is not retriable without a new job",
                    "job_id": job_id,
                },
            )

    job.cancelled = False
    job.error = None
    job.retry_count += 1
    job.status = JobStatus.queued
    job.stage = JobStatus.queued.value
    job.progress = 0.0
    store.save(job)

    detector = getattr(request.app.state, "detector", None)
    background_tasks.add_task(
        run_analysis_pipeline,
        job,
        settings=settings,
        store=store,
        detector=detector,
    )
    log_stage(
        logger,
        stage=job.stage,
        job_id=job.job_id,
        video_id=job.video_id,
        message="Retry scheduled",
        retry_count=job.retry_count,
    )
    return RetryResponse(
        job_id=job.job_id,
        status=job.status,
        stage=job.stage,
        message="Retry scheduled from validating stage",
    )

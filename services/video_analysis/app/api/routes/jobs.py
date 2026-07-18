"""Cancel and retry routes."""

from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request

from app.api.ownership import assert_can_access
from app.api.schemas.responses import CancelResponse, JobStatus, RetryResponse
from app.auth import AuthUser, require_user
from app.services.job_pipeline import run_analysis_pipeline
from app.utils.logging import get_logger, log_stage

router = APIRouter(prefix="/v1/analyses", tags=["jobs"])
logger = get_logger("video_analysis.jobs")


@router.post("/{job_id}/cancel", response_model=CancelResponse)
async def cancel_job(
    job_id: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> CancelResponse:
    store = request.app.state.store
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)

    if job.status in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
        JobStatus.cancelled,
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
    if job.status in {JobStatus.queued, JobStatus.validating, JobStatus.preprocessing}:
        job.mark_failed(
            error_code="CANCELLED",
            message="Job cancelled by client",
            stage=job.stage,
            retriable=False,
        )
    else:
        # In-flight stages observe the cancelled flag and terminate.
        from app.domain.jobs import utc_now

        job.status = JobStatus.cancelled
        job.stage = JobStatus.cancelled.value
        job.updated_at = utc_now()
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
async def retry_job(
    job_id: str,
    background_tasks: BackgroundTasks,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> RetryResponse:
    settings = request.app.state.settings
    store = request.app.state.store
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)

    if job.status != JobStatus.failed:
        raise HTTPException(
            status_code=409,
            detail={
                "error_code": "NOT_RETRIABLE",
                "message": "Only failed jobs can be retried",
                "job_id": job_id,
            },
        )

    if job.error and not job.error.retriable:
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
    # Refresh session token so retries work after a storage-config fix.
    job.download_access_token = getattr(request.state, "access_token", None) or (
        job.download_access_token
    )
    store.save(job)

    if job.storage_path:
        from app.services.supabase_bridge import SupabaseBridge

        bridge = SupabaseBridge(settings)
        if not bridge.can_download(job.download_access_token):
            raise HTTPException(
                status_code=503,
                detail={
                    "error_code": "SERVER_UNAVAILABLE",
                    "message": (
                        "Supabase storage download is not configured on the Elite server. "
                        "Fix services/video_analysis/.env (SUPABASE_URL + SUPABASE_ANON_KEY), "
                        "restart the Elite server, stay signed in, then retry."
                    ),
                    "retriable": True,
                },
            )

    detector = getattr(request.app.state, "detector", None)

    def _run_retry(job_id: str) -> None:
        fresh = store.get(job_id)
        if fresh is None:
            return
        run_analysis_pipeline(
            fresh,
            settings=settings,
            store=store,
            detector=detector,
        )

    background_tasks.add_task(_run_retry, job.job_id)
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

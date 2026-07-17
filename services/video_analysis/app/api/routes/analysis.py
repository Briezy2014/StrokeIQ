"""Analysis job creation and results routes."""

from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, HTTPException, Request

from app.api.schemas.requests import CreateAnalysisRequest
from app.api.schemas.responses import (
    AnalysisResultsResponse,
    CreateAnalysisResponse,
    JobStatus,
    JobStatusResponse,
    VideoMetadataResult,
)
from app.config import Settings, get_settings
from app.domain.jobs import AnalysisJob, new_job_id
from app.services.job_pipeline import run_milestone1_pipeline
from app.services.result_store import ResultStore
from app.utils.logging import get_logger, log_stage

router = APIRouter(prefix="/v1/analyses", tags=["analysis"])
logger = get_logger("video_analysis.api")


def _store(request: Request) -> ResultStore:
    return request.app.state.store


def _settings(request: Request) -> Settings:
    return request.app.state.settings


def _process_job(job_id: str, settings: Settings, store: ResultStore) -> None:
    job = store.get(job_id)
    if job is None:
        return
    run_milestone1_pipeline(job, settings=settings, store=store)


@router.post("", response_model=CreateAnalysisResponse, status_code=202)
def create_analysis(
    body: CreateAnalysisRequest,
    background_tasks: BackgroundTasks,
    request: Request,
) -> CreateAnalysisResponse:
    settings = _settings(request)
    store = _store(request)

    if not body.local_path and not body.storage_path:
        raise HTTPException(
            status_code=400,
            detail={
                "error_code": "PATH_REQUIRED",
                "message": "Provide local_path (Milestone 1) or storage_path.",
            },
        )

    job = AnalysisJob(
        job_id=new_job_id(),
        video_id=body.video_id,
        engine_version=settings.engine_version,
        request_payload=body.model_dump(),
        local_path=body.local_path,
        storage_bucket=body.storage_bucket,
        storage_path=body.storage_path,
    )
    store.save(job)
    log_stage(
        logger,
        stage=job.stage,
        job_id=job.job_id,
        video_id=job.video_id,
        message="Job created",
    )

    background_tasks.add_task(_process_job, job.job_id, settings, store)

    return CreateAnalysisResponse(
        job_id=job.job_id,
        status=job.status,
        stage=job.stage,
        video_id=job.video_id,
        engine_version=job.engine_version,
        created_at=job.created_at,
    )


@router.get("/{job_id}", response_model=JobStatusResponse)
def get_job_status(job_id: str, request: Request) -> JobStatusResponse:
    job = _store(request).get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    return JobStatusResponse(
        job_id=job.job_id,
        status=job.status,
        progress=job.progress,
        stage=job.stage,
        engine_version=job.engine_version,
        video_id=job.video_id,
        error=job.error,
        retry_count=job.retry_count,
        created_at=job.created_at,
        updated_at=job.updated_at,
    )


@router.get("/{job_id}/results", response_model=AnalysisResultsResponse)
def get_job_results(job_id: str, request: Request) -> AnalysisResultsResponse:
    job = _store(request).get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status not in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    }:
        raise HTTPException(
            status_code=409,
            detail={
                "error_code": "RESULTS_NOT_READY",
                "message": f"Job status is {job.status.value}; results not ready.",
                "job_id": job.job_id,
                "stage": job.stage,
            },
        )

    video = None
    if job.metadata:
        video = VideoMetadataResult(
            duration_ms=int(job.metadata["duration_ms"]),
            fps=float(job.metadata["fps"]),
            width=int(job.metadata["width"]),
            height=int(job.metadata["height"]),
            frame_count=job.metadata.get("frame_count"),
            codec=job.metadata.get("codec"),
            mime_type=job.metadata.get("mime_type"),
            rotation=job.metadata.get("rotation"),
            file_size_bytes=int(job.metadata["file_size_bytes"]),
            original_path=job.metadata["original_path"],
            normalized_path=job.metadata.get("normalized_path"),
            proxy_path=job.metadata.get("proxy_path"),
            quality_flags=list(job.metadata.get("quality_flags") or []),
            view=job.metadata.get("view") or "unknown",
            quality_score=job.metadata.get("quality_score"),
        )

    athlete = None
    stroke = None
    payload = job.request_payload or {}
    if payload.get("athlete"):
        athlete = payload["athlete"]
    if payload.get("event"):
        stroke = {
            "predicted": payload["event"].get("stroke") or "unknown",
            "confidence": None,
            "note": "Milestone 1 does not classify stroke from video.",
        }

    return AnalysisResultsResponse(
        job_id=job.job_id,
        status=job.status,
        engine_version=job.engine_version,
        video_id=job.video_id,
        video=video,
        athlete=athlete,
        stroke=stroke,
        phases=[],
        metrics=[],
        limitations=job.limitations,
        evidence_frames=[],
        model_versions={"engine": job.engine_version, "milestone": "1"},
        report=None,
        error=job.error,
        created_at=job.created_at,
        metadata_artifact_path=job.metadata_artifact_path,
    )

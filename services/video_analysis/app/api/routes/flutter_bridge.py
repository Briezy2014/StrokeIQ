"""Flutter-facing helpers: history, signed URLs, feedback, delete (Milestone 9)."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.api.ownership import assert_can_access
from app.auth import AuthUser, require_user
from app.services.supabase_bridge import SupabaseBridge, SupabaseBridgeError

router = APIRouter(prefix="/v1", tags=["flutter"])


class FeedbackRequest(BaseModel):
    feedback_type: str = "general"
    message: str = Field(min_length=3, max_length=4000)
    incorrect_fields: list[str] = Field(default_factory=list)
    payload: dict[str, Any] = Field(default_factory=dict)


class SignedUrlResponse(BaseModel):
    bucket: str
    storage_path: str
    signed_url: str
    expires_in: int


@router.get("/athletes/{swimmer_key}/analyses")
async def list_athlete_analyses(
    swimmer_key: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> dict[str, Any]:
    """Analysis history for an athlete owned by the authenticated user."""
    settings = request.app.state.settings
    store = request.app.state.store
    # Prefer in-memory/local store for tests; merge Supabase when enabled.
    local = [
        {
            "job_id": j.job_id,
            "video_id": j.video_id,
            "status": j.status.value,
            "stage": j.stage,
            "engine_version": j.engine_version,
            "engine_name": (j.model_versions or {}).get("engine_name")
            or settings.video_engine_name,
            "created_at": j.created_at.isoformat(),
            "updated_at": j.updated_at.isoformat(),
            "limitations": j.limitations,
            "has_report": bool((j.report or {}).get("gemini_succeeded")),
            "has_metrics": bool(
                j.butterfly or j.underwater or j.turn or j.finish
            ),
        }
        for j in store.list_jobs()
        if (j.owner_user_id in {None, user.user_id, "local-dev-user"})
        and (j.swimmer_key == swimmer_key or j.swimmer_key is None)
    ]
    remote: list[dict] = []
    if settings.supabase_persist_results:
        bridge = SupabaseBridge(settings)
        remote = bridge.list_jobs_for_user(user_id=user.user_id, swimmer_key=swimmer_key)
    return {"swimmer_key": swimmer_key, "jobs": local, "remote_jobs": remote}


@router.get("/analyses/{job_id}/signed-video-url", response_model=SignedUrlResponse)
async def signed_video_url(
    job_id: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> SignedUrlResponse:
    job = request.app.state.store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)
    if not job.storage_path:
        raise HTTPException(
            status_code=404,
            detail={"error_code": "INVALID_VIDEO", "message": "No storage path on job"},
        )
    settings = request.app.state.settings
    bridge = SupabaseBridge(settings)
    try:
        url = bridge.create_signed_url(
            bucket=job.storage_bucket or "swim-videos",
            storage_path=job.storage_path,
            expires_in=settings.supabase_signed_url_ttl_s,
        )
    except SupabaseBridgeError as exc:
        raise HTTPException(
            status_code=503,
            detail={"error_code": exc.code, "message": exc.message},
        ) from exc
    return SignedUrlResponse(
        bucket=job.storage_bucket or "swim-videos",
        storage_path=job.storage_path,
        signed_url=url,
        expires_in=settings.supabase_signed_url_ttl_s,
    )


@router.post("/analyses/{job_id}/feedback")
async def submit_feedback(
    job_id: str,
    body: FeedbackRequest,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> dict[str, Any]:
    job = request.app.state.store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)
    settings = request.app.state.settings
    # Always keep a local copy for diagnostics
    feedback_dir = settings.artifact_root / job_id / "feedback"
    feedback_dir.mkdir(parents=True, exist_ok=True)
    path = feedback_dir / "feedback.jsonl"
    import json
    from datetime import datetime, timezone

    record = {
        "job_id": job_id,
        "user_id": user.user_id,
        "feedback_type": body.feedback_type,
        "message": body.message,
        "incorrect_fields": body.incorrect_fields,
        "payload": body.payload,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record) + "\n")
    if settings.supabase_persist_results and settings.supabase_service_role_key:
        try:
            SupabaseBridge(settings).insert_feedback(
                job_id=job_id,
                user_id=user.user_id,
                feedback_type=body.feedback_type,
                message=body.message,
                incorrect_fields=body.incorrect_fields,
                payload=body.payload,
            )
        except SupabaseBridgeError:
            pass
    return {"ok": True, "job_id": job_id}


@router.delete("/analyses/{job_id}")
async def delete_analysis(
    job_id: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> dict[str, Any]:
    store = request.app.state.store
    job = store.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)
    settings = request.app.state.settings
    if settings.supabase_persist_results and settings.supabase_service_role_key:
        SupabaseBridge(settings).soft_delete_job(job_id, user_id=user.user_id)
    # Soft-delete locally: mark cancelled + drop from active list if store supports
    job.cancelled = True
    from app.api.schemas.responses import JobStatus

    job.status = JobStatus.cancelled
    job.stage = JobStatus.cancelled.value
    job.limitations = list(dict.fromkeys([*job.limitations, "deleted_by_user"]))
    store.save(job)
    return {"ok": True, "job_id": job_id, "status": "cancelled"}

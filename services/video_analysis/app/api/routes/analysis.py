"""Analysis job creation and results routes."""

from __future__ import annotations

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request

from app.api.ownership import assert_can_access, attach_owner
from app.api.schemas.requests import CreateAnalysisRequest
from app.api.schemas.responses import (
    AnalysisResultsResponse,
    CreateAnalysisResponse,
    JobStatus,
    JobStatusResponse,
    VideoMetadataResult,
)
from app.auth import AuthUser, require_user
from app.config import Settings
from app.domain.jobs import AnalysisJob, new_job_id
from app.models.detector_adapter import DetectorAdapter
from app.services.job_pipeline import run_analysis_pipeline
from app.services.result_store import ResultStore
from app.utils.logging import get_logger, log_stage

router = APIRouter(prefix="/v1/analyses", tags=["analysis"])
logger = get_logger("video_analysis.api")


def _store(request: Request) -> ResultStore:
    return request.app.state.store


def _settings(request: Request) -> Settings:
    return request.app.state.settings


def _detector(request: Request) -> DetectorAdapter | None:
    return getattr(request.app.state, "detector", None)


def _process_job(
    job_id: str,
    settings: Settings,
    store: ResultStore,
    detector: DetectorAdapter | None,
) -> None:
    job = store.get(job_id)
    if job is None:
        return
    run_analysis_pipeline(job, settings=settings, store=store, detector=detector)


@router.post("", response_model=CreateAnalysisResponse, status_code=202)
async def create_analysis(
    body: CreateAnalysisRequest,
    background_tasks: BackgroundTasks,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> CreateAnalysisResponse:
    settings = _settings(request)
    store = _store(request)
    detector = _detector(request)

    if not body.local_path and not body.storage_path:
        raise HTTPException(
            status_code=400,
            detail={
                "error_code": "PATH_REQUIRED",
                "message": "Provide local_path (Milestone 1/2) or storage_path.",
            },
        )

    access_token = getattr(request.state, "access_token", None)
    if body.storage_path:
        from app.services.supabase_bridge import SupabaseBridge

        bridge = SupabaseBridge(settings)
        if not bridge.can_download(access_token):
            raise HTTPException(
                status_code=503,
                detail={
                    "error_code": "SERVER_UNAVAILABLE",
                    "message": (
                        "Supabase storage download is not configured on the Elite server. "
                        "Ensure services/video_analysis/.env has SUPABASE_URL and "
                        "SUPABASE_ANON_KEY (copied from swimiq/.env), restart "
                        "START-SWIMIQ-WITH-ELITE.bat, and stay signed in."
                    ),
                    "retriable": True,
                },
            )

    # Production / Flutter mode: never accept arbitrary server filesystem paths.
    if settings.supabase_auth_required and body.local_path:
        raise HTTPException(
            status_code=400,
            detail={
                "error_code": "LOCAL_PATH_FORBIDDEN",
                "message": "local_path is not allowed when Supabase auth is required. Use storage_path.",
            },
        )

    if settings.supabase_auth_required and body.storage_path:
        from app.services.supabase_bridge import SupabaseBridge

        bridge = SupabaseBridge(settings)
        if not bridge.user_owns_storage_path(
            user_id=user.user_id,
            storage_path=body.storage_path,
            video_id=body.video_id,
        ):
            raise HTTPException(
                status_code=403,
                detail={
                    "error_code": "NOT_OWNER",
                    "message": "You do not have access to this video.",
                },
            )

    athlete_key = body.athlete.swimmer_key if body.athlete else None
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id=body.video_id,
        engine_version=settings.engine_version,
        request_payload=body.model_dump(),
        local_path=body.local_path,
        storage_bucket=body.storage_bucket,
        storage_path=body.storage_path,
    )
    attach_owner(job, user, athlete_key)
    job.model_versions["engine_name"] = settings.video_engine_name
    # Keep Flutter session token for storage download when service-role is unset.
    job.download_access_token = access_token
    store.save(job)
    log_stage(
        logger,
        stage=job.stage,
        job_id=job.job_id,
        video_id=job.video_id,
        message="Job created",
        owner_user_id=user.user_id,
        engine_name=settings.video_engine_name,
    )

    background_tasks.add_task(_process_job, job.job_id, settings, store, detector)

    return CreateAnalysisResponse(
        job_id=job.job_id,
        status=job.status,
        stage=job.stage,
        video_id=job.video_id,
        engine_version=job.engine_version,
        created_at=job.created_at,
    )


@router.get("/{job_id}", response_model=JobStatusResponse)
async def get_job_status(
    job_id: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> JobStatusResponse:
    job = _store(request).get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)
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
async def get_job_results(
    job_id: str,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> AnalysisResultsResponse:
    job = _store(request).get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found")
    assert_can_access(job, user)

    if job.status not in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
        JobStatus.cancelled,
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
        athlete = dict(payload["athlete"])
        if job.tracking and job.tracking.get("target"):
            athlete["track_id"] = job.tracking["target"].get("track_id")
            athlete["tracking_confidence"] = job.tracking["target"].get(
                "target_identity_confidence"
            )
    if payload.get("event"):
        stroke = {
            "predicted": payload["event"].get("stroke") or "unknown",
            "confidence": None,
            "note": "Stroke classification from video begins in a later milestone.",
        }

    evidence = []
    if job.tracking and job.tracking.get("artifact_paths"):
        frames = job.tracking["artifact_paths"].get("selected_target_frames") or []
        evidence = [{"path": p} for p in frames]

    model_versions = {"engine": job.engine_version, "milestone": "9"}
    model_versions.update(job.model_versions or {})

    if job.pose:
        model_versions["pose_stage"] = str(job.pose.get("stage"))
        if job.pose.get("artifact_paths"):
            evidence.append({"pose_artifacts": job.pose["artifact_paths"]})

    metrics = []
    phases = []
    # Tracking-only Elite runs (pose/M5–M7 off) still expose usable metrics.
    try:
        from app.services.report.context import collect_deterministic_payloads

        tracking_metrics, _tracking_events = collect_deterministic_payloads(job)
        for m in tracking_metrics:
            name = str(m.get("name") or "")
            if name.startswith("target_") or name in {
                "target_coverage",
                "processed_frames",
                "frames_with_detections",
            } or str(m.get("metric_id") or "").startswith("tracking:"):
                metrics.append(m)
    except Exception:  # noqa: BLE001
        pass
    if job.butterfly:
        metrics = list(job.butterfly.get("metrics") or [])
        for c in job.butterfly.get("cycles") or []:
            phases.append(
                {
                    "name": "butterfly_stroke_cycle",
                    "start_ms": int(c.get("start_ms") or 0),
                    "end_ms": int(c.get("end_ms") or 0),
                    "start_frame": c.get("start_frame"),
                    "end_frame": c.get("end_frame"),
                    "confidence": c.get("confidence") or 0.0,
                    "editable": True,
                    "quality_flags": c.get("quality_flags") or [],
                    "evidence_frames": [c.get("entry_frame"), c.get("next_entry_frame")],
                }
            )
        if job.butterfly.get("artifact_paths"):
            evidence.append({"butterfly_artifacts": job.butterfly["artifact_paths"]})
        if stroke is not None:
            stroke = {
                **stroke,
                "note": "Surface butterfly metrics from Milestone 5; stroke ID still request-hinted.",
                "butterfly_summary": job.butterfly.get("summary"),
            }

    if job.underwater:
        metrics = list(metrics) + list(job.underwater.get("metrics") or [])
        phase = job.underwater.get("phase")
        if phase:
            phases.append(
                {
                    "name": "underwater_phase",
                    "start_ms": int(phase.get("start_ms") or 0),
                    "end_ms": int(phase.get("end_ms") or 0),
                    "start_frame": phase.get("start_frame"),
                    "end_frame": phase.get("end_frame"),
                    "confidence": phase.get("confidence") or 0.0,
                    "editable": True,
                    "quality_flags": phase.get("quality_flags") or [],
                    "evidence_frames": [
                        job.underwater.get("breakout_frame"),
                        *(job.underwater.get("kick_frames") or [])[:4],
                    ],
                }
            )
        if job.underwater.get("artifact_paths"):
            evidence.append({"underwater_artifacts": job.underwater["artifact_paths"]})
        if stroke is not None:
            stroke = {
                **stroke,
                "underwater_summary": job.underwater.get("summary"),
            }

    if job.turn:
        metrics = list(metrics) + list(job.turn.get("metrics") or [])
        if job.turn.get("artifact_paths"):
            evidence.append({"turn_artifacts": job.turn["artifact_paths"]})
    if job.finish:
        metrics = list(metrics) + list(job.finish.get("metrics") or [])
        if job.finish.get("artifact_paths"):
            evidence.append({"finish_artifacts": job.finish["artifact_paths"]})

    return AnalysisResultsResponse(
        job_id=job.job_id,
        status=job.status,
        engine_version=job.engine_version,
        video_id=job.video_id,
        video=video,
        athlete=athlete,
        stroke=stroke,
        tracking={
            **(job.tracking or {}),
            **({"pose": job.pose} if job.pose else {}),
            **({"butterfly": job.butterfly} if job.butterfly else {}),
            **({"underwater": job.underwater} if job.underwater else {}),
            **({"turn": job.turn} if job.turn else {}),
            **({"finish": job.finish} if job.finish else {}),
        }
        if (job.tracking or job.pose or job.butterfly or job.underwater or job.turn or job.finish)
        else None,
        phases=phases,
        metrics=metrics,
        limitations=job.limitations,
        evidence_frames=evidence,
        model_versions=model_versions,
        report=_flutter_facing_report(job.report),
        error=job.error,
        created_at=job.created_at,
        metadata_artifact_path=job.metadata_artifact_path,
    )


def _flutter_facing_report(job_report: dict | None) -> dict | None:
    """Flatten StoredCoachingReport into the shape Flutter AnalysisReport expects.

    Pipeline stores: {gemini_succeeded, report: StoredCoachingReport{report: body}}.
    Flutter reads top-level summary/strengths/priority_improvements strings.
    """
    if not isinstance(job_report, dict):
        return None
    gemini_ok = bool(job_report.get("gemini_succeeded"))
    stored = job_report.get("report")
    if not isinstance(stored, dict):
        return None

    # Real pipeline shape: StoredCoachingReport with nested CoachingReportBody.
    body = stored.get("report")
    if isinstance(body, dict) and (
        body.get("summary") is not None or body.get("strengths") is not None
    ):
        strengths_out: list[str] = []
        for item in body.get("strengths") or []:
            if isinstance(item, dict):
                text = str(item.get("text") or "").strip()
                if text:
                    strengths_out.append(text)
            elif item is not None:
                strengths_out.append(str(item))

        improvements_out: list[dict] = []
        for item in body.get("priority_improvements") or []:
            if not isinstance(item, dict):
                continue
            obs = item.get("observation") if isinstance(item.get("observation"), dict) else {}
            title = str(obs.get("text") or item.get("title") or "").strip()
            drills = [str(d) for d in (item.get("drills") or []) if str(d).strip()]
            if title:
                improvements_out.append({"title": title, "drills": drills})

        limitations = body.get("limitations") or []
        limitations_statement = None
        if isinstance(limitations, list) and limitations:
            limitations_statement = "; ".join(str(x) for x in limitations if str(x).strip())
        elif isinstance(limitations, str):
            limitations_statement = limitations

        return {
            "summary": body.get("summary"),
            "strengths": strengths_out,
            "priority_improvements": improvements_out,
            "race_recommendations": list(body.get("race_recommendations") or []),
            # Do not duplicate improvement drills into a top-level list
            # (that made the Coaching tab show the same drills twice).
            "drills": [],
            "limitations_statement": limitations_statement
            or body.get("limitations_statement"),
            "confidence_statement": body.get("confidence_statement"),
            "model": stored.get("model_name") or body.get("model"),
            "gemini_succeeded": gemini_ok,
            "failure_code": stored.get("failure_code"),
            "status": stored.get("status"),
            "created_at": stored.get("generation_timestamp"),
        }

    # Already-flat / test shape: summary on the stored dict itself.
    if stored.get("summary") is not None or stored.get("strengths") is not None:
        out = dict(stored)
        out["gemini_succeeded"] = gemini_ok
        return out

    # Failed report with no body — still pass failure_code for UI messaging.
    if stored.get("failure_code") or stored.get("status") == "failed":
        return {
            "gemini_succeeded": False,
            "failure_code": stored.get("failure_code"),
            "status": stored.get("status") or "failed",
            "model": stored.get("model_name"),
        }
    return None

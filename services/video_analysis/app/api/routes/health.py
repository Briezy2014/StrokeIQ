"""Health endpoint."""

from __future__ import annotations

import shutil
from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.api.schemas.responses import HealthResponse
from app.config import get_settings
from app.models.model_registry import resolve_detector_model_path
from app.services.pose_pipeline import health_pose_model

router = APIRouter(tags=["health"])


def _configured(value: str | None) -> bool:
    raw = (value or "").strip()
    if not raw:
        return False
    lowered = raw.lower()
    return not any(
        marker in lowered
        for marker in (
            "your-project",
            "your-supabase",
            "your_anon",
            "paste_",
            "changeme",
        )
    )


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    ffmpeg_path = shutil.which(settings.ffmpeg_path) or settings.ffmpeg_path
    ffprobe_path = shutil.which(settings.ffprobe_path) or settings.ffprobe_path
    ffmpeg_available = shutil.which(settings.ffmpeg_path) is not None
    ffprobe_available = shutil.which(settings.ffprobe_path) is not None
    model_path = resolve_detector_model_path(settings.detector_model_path)
    model_available = Path(model_path).is_file()

    url_ok = _configured(settings.supabase_url)
    anon_ok = _configured(settings.supabase_anon_key)
    service_ok = _configured(settings.supabase_service_role_key)
    storage_ok = service_ok or (url_ok and anon_ok)

    media_ok = ffmpeg_available and ffprobe_available
    status = "ok" if media_ok and storage_ok else "degraded"
    # Keep prior "ok" when only the optional detector model file is missing.
    if media_ok and storage_ok and not model_available:
        status = "ok"

    gemini_ok = _configured(settings.gemini_api_key)
    return HealthResponse(
        status=status,
        engine_version=settings.engine_version,
        ffmpeg_available=ffmpeg_available,
        ffprobe_available=ffprobe_available,
        ffmpeg_path=str(ffmpeg_path),
        ffprobe_path=str(ffprobe_path),
        supabase_url_configured=url_ok,
        supabase_anon_configured=anon_ok,
        supabase_service_role_configured=service_ok,
        storage_download_configured=storage_ok,
        gemini_api_key_configured=gemini_ok,
    )


@router.get("/health/pose")
def health_pose() -> JSONResponse:
    """Model-loading health check for RTMPose WholeBody (Milestone 3)."""
    settings = get_settings()
    report = health_pose_model(settings)
    ok = bool(report.get("pose_model_loaded")) and bool(
        report.get("pose_checkpoint_present")
    )
    return JSONResponse(
        status_code=200 if ok else 503,
        content={"status": "ok" if ok else "degraded", **report},
    )

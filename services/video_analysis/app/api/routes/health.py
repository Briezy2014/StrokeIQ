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


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    ffmpeg_path = shutil.which(settings.ffmpeg_path) or settings.ffmpeg_path
    ffprobe_path = shutil.which(settings.ffprobe_path) or settings.ffprobe_path
    ffmpeg_available = shutil.which(settings.ffmpeg_path) is not None
    ffprobe_available = shutil.which(settings.ffprobe_path) is not None
    model_path = resolve_detector_model_path(settings.detector_model_path)
    model_available = Path(model_path).is_file()

    status = "ok" if ffmpeg_available and ffprobe_available and model_available else "degraded"
    return HealthResponse(
        status=status,
        engine_version=settings.engine_version,
        ffmpeg_available=ffmpeg_available,
        ffprobe_available=ffprobe_available,
        ffmpeg_path=ffmpeg_path,
        ffprobe_path=ffprobe_path,
    )


@router.get("/health/pose")
def health_pose() -> JSONResponse:
    """Model-loading health check for RTMPose WholeBody (Milestone 3)."""
    settings = get_settings()
    report = health_pose_model(settings)
    ok = bool(report.get("pose_model_loaded")) and bool(report.get("pose_checkpoint_present"))
    return JSONResponse(
        status_code=200 if ok else 503,
        content={"status": "ok" if ok else "degraded", **report},
    )

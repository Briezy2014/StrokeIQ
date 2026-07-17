"""Health endpoint."""

from __future__ import annotations

import shutil

from fastapi import APIRouter

from app.api.schemas.responses import HealthResponse
from app.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    settings = get_settings()
    ffmpeg_path = shutil.which(settings.ffmpeg_path) or settings.ffmpeg_path
    ffprobe_path = shutil.which(settings.ffprobe_path) or settings.ffprobe_path
    ffmpeg_available = shutil.which(settings.ffmpeg_path) is not None
    ffprobe_available = shutil.which(settings.ffprobe_path) is not None

    status = "ok" if ffmpeg_available and ffprobe_available else "degraded"
    return HealthResponse(
        status=status,
        engine_version=settings.engine_version,
        ffmpeg_available=ffmpeg_available,
        ffprobe_available=ffprobe_available,
        ffmpeg_path=ffmpeg_path,
        ffprobe_path=ffprobe_path,
    )

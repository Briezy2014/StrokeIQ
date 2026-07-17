"""Elote Video Lab analysis service — Milestone 1 entrypoint."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import analysis, health, jobs
from app.config import get_settings
from app.services.result_store import ResultStore
from app.utils.logging import configure_logging, get_logger, log_stage

logger = get_logger("video_analysis")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    configure_logging(settings.log_level)
    settings.ensure_dirs()
    store = ResultStore(settings.job_store_path)
    app.state.settings = settings
    app.state.store = store
    log_stage(
        logger,
        stage="startup",
        message="Elote Video Lab analysis service started",
        engine_version=settings.engine_version,
    )
    yield


app = FastAPI(
    title="Elote Video Lab Analysis Service",
    version="0.1.0",
    description=(
        "Elote Video Lab: validation, RTMDet tracking, RTMPose WholeBody, "
        "M4–M7 biomechanics, M8 confidence-aware Gemini coaching reports from "
        "structured CV results only (never raw video). No Flutter integration yet."
    ),
    lifespan=lifespan,
)

app.include_router(health.router)
app.include_router(analysis.router)
app.include_router(jobs.router)

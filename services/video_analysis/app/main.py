"""Elite Video Lab analysis service — Milestone 9 entrypoint."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import analysis, flutter_bridge, health, jobs
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
        message="Elite Video Lab analysis service started",
        engine_version=settings.engine_version,
        engine_name=settings.video_engine_name,
    )
    yield


app = FastAPI(
    title="Elite Video Lab Analysis Service",
    version="0.9.0",
    description=(
        "Elite Video Lab Video Engine V2: FastAPI CV pipeline + Gemini coaching "
        "reports. Flutter connects via authenticated /v1 APIs. Secrets stay server-side."
    ),
    lifespan=lifespan,
)

_settings = get_settings()
_origins = [o.strip() for o in (_settings.cors_allow_origins or "*").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins if _origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(analysis.router)
app.include_router(jobs.router)
app.include_router(flutter_bridge.router)

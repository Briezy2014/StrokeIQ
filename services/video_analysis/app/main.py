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
    url_ok = bool((settings.supabase_url or "").strip())
    anon_ok = bool((settings.supabase_anon_key or "").strip())
    service_ok = bool((settings.supabase_service_role_key or "").strip())
    # Warm-load RTMDet once so the first analyze is not paying cold ONNX startup.
    detector = None
    try:
        from app.services.swimmer_detector import build_detector

        detector = build_detector(settings)
        app.state.detector = detector
        logger.info("Detector warm-loaded: %s", getattr(detector, "model_name", "ok"))
    except Exception as exc:  # noqa: BLE001
        app.state.detector = None
        logger.warning("Detector warm-load skipped: %s", exc)

    gemini_ok = bool((settings.gemini_api_key or "").strip())
    log_stage(
        logger,
        stage="startup",
        message="Elite Video Lab analysis service started",
        engine_version=settings.engine_version,
        engine_name=settings.video_engine_name,
        supabase_url_configured=url_ok,
        supabase_anon_configured=anon_ok,
        supabase_service_role_configured=service_ok,
        storage_download_configured=service_ok or (url_ok and anon_ok),
        gemini_api_key_configured=gemini_ok,
        detector_warm_loaded=detector is not None,
    )
    if not (service_ok or (url_ok and anon_ok)):
        logger.error(
            "STORAGE NOT CONFIGURED: set SUPABASE_URL + SUPABASE_ANON_KEY in "
            "services/video_analysis/.env (copied from swimiq/.env) and restart."
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
# Bearer tokens use the Authorization header (not cookies). Keep credentials
# off when origins are "*", so Flutter web browsers accept ACAO: *.
_allow_all = _origins == ["*"] or not _origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all else _origins,
    allow_credentials=not _allow_all,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.include_router(health.router)
app.include_router(analysis.router)
app.include_router(jobs.router)
app.include_router(flutter_bridge.router)

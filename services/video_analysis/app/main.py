"""Elite Video Lab analysis service — Milestone 9 entrypoint."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import analysis, best_times, flutter_bridge, health, jobs
from app.config import get_settings
from app.services.result_store import ResultStore
from app.utils.logging import configure_logging, get_logger, log_stage

logger = get_logger("video_analysis")


class PrivateNetworkAccessMiddleware:
    """Allow swimiqapp.com (public site) to call Elite on 127.0.0.1 (Chrome PNA)."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_pna(message):
            if message["type"] == "http.response.start":
                headers = list(message.get("headers") or [])
                headers.append((b"access-control-allow-private-network", b"true"))
                message = {**message, "headers": headers}
            await send(message)

        await self.app(scope, receive, send_with_pna)


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
# After CORS so preflight responses also advertise private-network access.
app.add_middleware(PrivateNetworkAccessMiddleware)


@app.middleware("http")
async def handle_private_network_preflight(request: Request, call_next):
    # Chrome sends Access-Control-Request-Private-Network: true on preflight
    # when a public page (swimiqapp.com) calls http://127.0.0.1:8080.
    if (
        request.method == "OPTIONS"
        and request.headers.get("access-control-request-private-network", "").lower()
        == "true"
    ):
        origin = request.headers.get("origin", "*")
        return Response(
            status_code=204,
            headers={
                "Access-Control-Allow-Origin": origin or "*",
                "Access-Control-Allow-Methods": "*",
                "Access-Control-Allow-Headers": request.headers.get(
                    "access-control-request-headers", "*"
                ),
                "Access-Control-Allow-Private-Network": "true",
                "Access-Control-Max-Age": "600",
            },
        )
    return await call_next(request)


app.include_router(health.router)
app.include_router(analysis.router)
app.include_router(jobs.router)
app.include_router(flutter_bridge.router)
app.include_router(best_times.router)

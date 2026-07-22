"""Highlight reel clip-pack + auto-stitch API for recruiting."""

from __future__ import annotations

from pathlib import Path
from typing import Any
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from app.auth import AuthUser, require_user
from app.services.highlight_reel import HighlightReelError, build_highlight_reel
from app.services.supabase_bridge import SupabaseBridge, SupabaseBridgeError

router = APIRouter(prefix="/v1", tags=["highlight-reels"])


class HighlightSegmentIn(BaseModel):
    storage_bucket: str = "swim-videos"
    storage_path: str = ""
    label: str = Field(min_length=1, max_length=120)
    tag: str = Field(min_length=1, max_length=40)
    start_ms: int | None = None
    end_ms: int | None = None
    # Local Elite / unit-test path (same pattern as analysis jobs).
    local_path: str | None = None


class HighlightReelRequest(BaseModel):
    segments: list[HighlightSegmentIn] = Field(min_length=1, max_length=24)
    title: str = Field(default="Recruiting Highlight Reel", max_length=120)
    max_clip_ms: int = Field(default=6000, ge=1500, le=15000)


class HighlightClipOut(BaseModel):
    label: str
    tag: str
    start_ms: int
    end_ms: int
    file_name: str
    download_url: str


class HighlightReelResponse(BaseModel):
    reel_id: str
    title: str
    reel_url: str
    clips: list[HighlightClipOut]
    download_token: str
    message: str


# Short-lived in-memory tokens so browser <a href> downloads work without
# attaching an Authorization header (local Elite + Flutter web).
_DOWNLOAD_TOKENS: dict[str, str] = {}


def _issue_download_token(reel_id: str) -> str:
    token = uuid4().hex
    _DOWNLOAD_TOKENS[token] = reel_id
    # Soft cap so long-running Elite processes don't grow forever.
    if len(_DOWNLOAD_TOKENS) > 200:
        for old in list(_DOWNLOAD_TOKENS.keys())[:50]:
            _DOWNLOAD_TOKENS.pop(old, None)
    return token


def _http_error(exc: HighlightReelError) -> HTTPException:
    status = 400
    if exc.code in {"FFMPEG_UNAVAILABLE", "SERVER_UNAVAILABLE"}:
        status = 503
    if exc.code in {"UPLOAD_FAILED"}:
        status = 502
    return HTTPException(
        status_code=status,
        detail={"error_code": exc.code, "message": exc.message},
    )


def _public_base(request: Request) -> str:
    # Prefer configured public URL; fall back to the request host (local Elite).
    settings = request.app.state.settings
    configured = (getattr(settings, "public_base_url", None) or "").strip()
    if configured:
        return configured.rstrip("/")
    return str(request.base_url).rstrip("/")


@router.post("/highlight-reels", response_model=HighlightReelResponse)
async def create_highlight_reel(
    body: HighlightReelRequest,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> HighlightReelResponse:
    settings = request.app.state.settings
    bridge = SupabaseBridge(settings)
    access_token = getattr(request.state, "access_token", None)
    download_cache: dict[str, Path] = {}

    def resolve_source(seg: dict[str, Any]) -> Path:
        local = (seg.get("local_path") or "").strip()
        if local:
            path = Path(local)
            if not path.exists():
                raise HighlightReelError("INVALID_VIDEO", f"Local video missing: {local}")
            return path

        storage_path = (seg.get("storage_path") or "").strip()
        if not storage_path:
            raise HighlightReelError(
                "INVALID_VIDEO",
                "Each clip needs a storage_path from Video Lab.",
            )
        bucket = (seg.get("storage_bucket") or "swim-videos").strip()
        cache_key = f"{bucket}:{storage_path}"
        if cache_key in download_cache:
            return download_cache[cache_key]

        dest = (
            settings.artifact_root
            / "highlight_sources"
            / user.user_id
            / storage_path.replace("/", "__")
        )
        if dest.exists() and dest.stat().st_size > 1000:
            download_cache[cache_key] = dest
            return dest
        try:
            bridge.download_storage_object(
                bucket=bucket,
                storage_path=storage_path,
                dest=dest,
                user_access_token=access_token,
            )
        except SupabaseBridgeError as exc:
            raise HighlightReelError(exc.code, exc.message) from exc
        download_cache[cache_key] = dest
        return dest

    try:
        built = build_highlight_reel(
            settings=settings,
            segments=[s.model_dump() for s in body.segments],
            source_resolver=resolve_source,
            max_clip_ms=body.max_clip_ms,
            title=body.title,
        )
    except HighlightReelError as exc:
        raise _http_error(exc) from exc

    reel_id = built["reel_id"]
    token = _issue_download_token(reel_id)
    base = _public_base(request)
    clips_out: list[HighlightClipOut] = []
    for clip in built["clips"]:
        clips_out.append(
            HighlightClipOut(
                label=clip.label,
                tag=clip.tag,
                start_ms=clip.start_ms,
                end_ms=clip.end_ms,
                file_name=clip.file_name,
                download_url=(
                    f"{base}/v1/highlight-reels/{reel_id}/files/clips/"
                    f"{clip.file_name}?token={token}"
                ),
            )
        )

    return HighlightReelResponse(
        reel_id=reel_id,
        title=built["title"],
        reel_url=(
            f"{base}/v1/highlight-reels/{reel_id}/files/"
            f"{built['reel_file']}?token={token}"
        ),
        clips=clips_out,
        download_token=token,
        message=(
            "Recruiting reel ready — download the full MP4 or grab individual "
            "clips from the pack."
        ),
    )


@router.get("/highlight-reels/{reel_id}/files/{file_name}")
async def download_reel_file(
    reel_id: str,
    file_name: str,
    request: Request,
    token: str = Query(..., min_length=8),
):
    _assert_download_token(reel_id=reel_id, token=token)
    return _serve_reel_file(
        request=request,
        reel_id=reel_id,
        relative=file_name,
    )


@router.get("/highlight-reels/{reel_id}/files/clips/{file_name}")
async def download_clip_file(
    reel_id: str,
    file_name: str,
    request: Request,
    token: str = Query(..., min_length=8),
):
    _assert_download_token(reel_id=reel_id, token=token)
    return _serve_reel_file(
        request=request,
        reel_id=reel_id,
        relative=f"clips/{file_name}",
    )


def _assert_download_token(*, reel_id: str, token: str) -> None:
    if _DOWNLOAD_TOKENS.get(token) != reel_id:
        raise HTTPException(status_code=401, detail="Invalid or expired download token")


def _serve_reel_file(
    *,
    request: Request,
    reel_id: str,
    relative: str,
) -> FileResponse:
    # Path traversal guard.
    if ".." in relative or relative.startswith("/") or "\\" in relative:
        raise HTTPException(status_code=400, detail="Invalid file path")
    settings = request.app.state.settings
    root = (settings.artifact_root / "highlight_reels" / reel_id).resolve()
    target = (root / relative).resolve()
    if not str(target).startswith(str(root)) or not target.exists():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(
        path=target,
        media_type="video/mp4",
        filename=target.name,
    )

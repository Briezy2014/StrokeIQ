"""Extract multiple PB rows from a Best Times History photo."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.auth import AuthUser, require_user
from app.services.best_times_extract import (
    decode_data_url_or_base64,
    extract_best_times_from_image,
    result_to_dict,
)
from app.services.report.client import GeminiClientError

router = APIRouter(prefix="/v1", tags=["best-times"])


class ExtractBestTimesRequest(BaseModel):
    image_base64: str = Field(min_length=32)
    mime_type: str | None = None
    course_hint: str | None = None


@router.post("/extract-best-times")
async def extract_best_times(
    body: ExtractBestTimesRequest,
    request: Request,
    user: AuthUser = Depends(require_user),
) -> dict[str, Any]:
    settings = request.app.state.settings
    api_key = (settings.gemini_api_key or "").strip()
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail={
                "error_code": "MISSING_API_KEY",
                "message": "GEMINI_API_KEY is not configured on the Elite server.",
            },
        )

    try:
        image_bytes, detected_mime = decode_data_url_or_base64(body.image_base64)
        mime = (body.mime_type or detected_mime or "image/jpeg").strip()
        result = extract_best_times_from_image(
            image_bytes=image_bytes,
            mime_type=mime,
            api_key=api_key,
            model_name=settings.gemini_model_name or "gemini-3.5-flash",
            course_hint=body.course_hint,
        )
    except GeminiClientError as exc:
        status = 400 if exc.code in {"EMPTY_IMAGE", "BAD_IMAGE_BASE64", "UNSUPPORTED_IMAGE", "IMAGE_TOO_LARGE"} else 502
        raise HTTPException(
            status_code=status,
            detail={"error_code": exc.code, "message": exc.message},
        ) from exc
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=500,
            detail={
                "error_code": "EXTRACT_FAILED",
                "message": f"Could not read best times from photo: {exc}",
            },
        ) from exc

    if not result.times:
        raise HTTPException(
            status_code=422,
            detail={
                "error_code": "NO_TIMES_FOUND",
                "message": (
                    "No swim times were found in that photo. "
                    "Use a clear Best Times History screenshot and try again."
                ),
            },
        )

    return {
        "ok": True,
        "engine": "swimiq-best-times-extract-v1",
        "user_id": user.user_id,
        **result_to_dict(result),
    }

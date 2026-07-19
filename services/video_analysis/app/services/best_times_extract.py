"""Extract multiple personal-best rows from a Best Times History screenshot."""

from __future__ import annotations

import base64
import json
import re
from typing import Any

from pydantic import BaseModel, Field

from app.services.report.client import GeminiClientError, GoogleGenAITransport
from app.utils.logging import get_logger

logger = get_logger("video_analysis.best_times_extract")

SYSTEM_PROMPT = """You extract swim personal-best rows from a screenshot.
The image is usually a Best Times History list (TeamUnify / OnDeck style).

Rules:
1. Return EVERY event row you can read (often 8–20 rows).
2. event: distance + stroke shorthand or full name (examples: 50 Fly, 100 Back, 200 IM, 500 Free).
3. time: swim time only (examples: 31.60, 1:12.05, 6:26.62). Never invent times.
4. course: SCY if times end with Y or yards; LCM if L or long course meters; SCM if S/short course meters.
5. date: MM/DD/YYYY when visible, else null.
6. meet_name: meet title when visible, else null.
7. Ignore profile headers, Active/Registered badges, SORT buttons, and time-standard selectors.
8. If the photo is not a times list, return an empty times array.
"""


class ExtractedBestTime(BaseModel):
    event: str = Field(min_length=2, max_length=80)
    time: str = Field(min_length=1, max_length=32)
    course: str | None = None
    date: str | None = None
    meet_name: str | None = None


class BestTimesExtractResult(BaseModel):
    times: list[ExtractedBestTime] = Field(default_factory=list)
    detected_course: str | None = None
    notes: str | None = None


def extract_best_times_from_image(
    *,
    image_bytes: bytes,
    mime_type: str,
    api_key: str,
    model_name: str = "gemini-2.5-flash",
    course_hint: str | None = None,
    timeout_s: float = 45.0,
) -> BestTimesExtractResult:
    if not image_bytes:
        raise GeminiClientError("EMPTY_IMAGE", "No image bytes provided")
    if len(image_bytes) > 12 * 1024 * 1024:
        raise GeminiClientError("IMAGE_TOO_LARGE", "Image must be under 12 MB")

    mime = (mime_type or "image/jpeg").split(";")[0].strip().lower()
    if mime not in {"image/jpeg", "image/jpg", "image/png", "image/webp"}:
        raise GeminiClientError("UNSUPPORTED_IMAGE", f"Unsupported image type: {mime}")

    hint = (course_hint or "").strip().upper()
    user_prompt = (
        "Extract all personal best rows from this Best Times History screenshot. "
        "Return JSON matching the schema."
    )
    if hint in {"SCY", "LCM", "SCM"}:
        user_prompt += f" Default course hint if unclear: {hint}."

    transport = GoogleGenAITransport(api_key=api_key)
    models = [model_name, "gemini-2.0-flash", "gemini-2.5-flash"]
    last_error: Exception | None = None
    for model in models:
        try:
            raw = transport.generate_json(
                model=model,
                system_prompt=SYSTEM_PROMPT,
                user_prompt=user_prompt,
                response_schema=BestTimesExtractResult,
                evidence_images=[(image_bytes, mime if mime != "image/jpg" else "image/jpeg")],
                timeout_s=timeout_s,
            )
            parsed = BestTimesExtractResult.model_validate(json.loads(raw.text))
            cleaned = _normalize_result(parsed, course_hint=hint or None)
            logger.info(
                "Extracted %s best-time rows via %s",
                len(cleaned.times),
                model,
            )
            return cleaned
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            logger.warning("Best-times extract failed on %s: %s", model, exc)
            continue

    if isinstance(last_error, GeminiClientError):
        raise last_error
    raise GeminiClientError(
        "EXTRACT_FAILED",
        f"Could not extract best times from photo: {last_error}",
        retriable=True,
    )


def _normalize_result(
    result: BestTimesExtractResult,
    *,
    course_hint: str | None,
) -> BestTimesExtractResult:
    rows: list[ExtractedBestTime] = []
    course_votes: dict[str, int] = {}
    for item in result.times:
        event = _clean_event(item.event)
        time_text = _clean_time(item.time)
        if not event or not time_text:
            continue
        course = _normalize_course(item.course) or _course_from_time_suffix(item.time)
        if course is None and course_hint in {"SCY", "LCM", "SCM"}:
            course = course_hint
        if course:
            course_votes[course] = course_votes.get(course, 0) + 1
        rows.append(
            ExtractedBestTime(
                event=event,
                time=time_text,
                course=course,
                date=_clean_date(item.date),
                meet_name=_clean_meet(item.meet_name),
            )
        )

    detected = result.detected_course
    if course_votes:
        detected = max(course_votes.items(), key=lambda kv: kv[1])[0]
    elif course_hint in {"SCY", "LCM", "SCM"}:
        detected = course_hint

    return BestTimesExtractResult(
        times=rows,
        detected_course=_normalize_course(detected),
        notes=(result.notes or "").strip() or None,
    )


def _clean_event(raw: str | None) -> str | None:
    text = (raw or "").strip()
    if not text:
        return None
    text = re.sub(r"\s+", " ", text)
    return text[:80]


def _clean_time(raw: str | None) -> str | None:
    text = (raw or "").strip().upper()
    if not text:
        return None
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"[YLS]$", "", text)
    m = re.search(r"(\d{1,2}:\d{2}\.\d{1,2}|\d{1,3}\.\d{1,2})", text)
    return m.group(1) if m else None


def _clean_date(raw: str | None) -> str | None:
    text = (raw or "").strip()
    if not text:
        return None
    m = re.search(r"(\d{1,2}/\d{1,2}/\d{2,4})", text)
    return m.group(1) if m else text[:32]


def _clean_meet(raw: str | None) -> str | None:
    text = (raw or "").strip()
    if not text:
        return None
    return re.sub(r"\s+", " ", text)[:120]


def _normalize_course(raw: str | None) -> str | None:
    text = (raw or "").strip().upper()
    if not text:
        return None
    if text in {"SCY", "Y", "YARDS", "SHORT COURSE YARDS"}:
        return "SCY"
    if text in {"LCM", "L", "LONG COURSE", "LONG COURSE METERS", "METERS"}:
        return "LCM"
    if text in {"SCM", "S", "SHORT COURSE METERS"}:
        return "SCM"
    return None


def _course_from_time_suffix(raw: str | None) -> str | None:
    text = (raw or "").strip().upper()
    if text.endswith("Y"):
        return "SCY"
    if text.endswith("L"):
        return "LCM"
    if text.endswith("S") and not text.endswith("SCY"):
        return "SCM"
    return None


def decode_data_url_or_base64(payload: str) -> tuple[bytes, str]:
    """Accept raw base64 or data:image/...;base64,..."""
    text = (payload or "").strip()
    if not text:
        raise GeminiClientError("EMPTY_IMAGE", "image_base64 is required")
    mime = "image/jpeg"
    if text.startswith("data:"):
        header, _, data = text.partition(",")
        mime_match = re.match(r"data:([^;]+);base64", header, flags=re.I)
        if mime_match:
            mime = mime_match.group(1)
        text = data
    try:
        return base64.b64decode(text, validate=False), mime
    except Exception as exc:  # noqa: BLE001
        raise GeminiClientError("BAD_IMAGE_BASE64", "Could not decode image_base64") from exc


def result_to_dict(result: BestTimesExtractResult) -> dict[str, Any]:
    return result.model_dump()

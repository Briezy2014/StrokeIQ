"""Google Gen AI SDK client wrapper with graceful failure modes."""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Protocol

from app.utils.logging import get_logger

logger = get_logger("video_analysis.report.client")


class GeminiClientError(Exception):
    def __init__(self, code: str, message: str, *, retriable: bool = False) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.retriable = retriable


@dataclass
class GeminiRawResponse:
    text: str
    model_version: str | None = None
    finish_reason: str | None = None
    safety_blocked: bool = False


class GeminiTransport(Protocol):
    def generate_json(
        self,
        *,
        model: str,
        system_prompt: str,
        user_prompt: str,
        response_schema: type,
        evidence_images: list[tuple[bytes, str]] | None = None,
        timeout_s: float = 45.0,
    ) -> GeminiRawResponse: ...


class GoogleGenAITransport:
    """Official `google-genai` SDK transport. API key from backend env only."""

    def __init__(self, *, api_key: str) -> None:
        if not api_key:
            raise GeminiClientError("MISSING_API_KEY", "GEMINI_API_KEY is not configured")
        from google import genai
        from google.genai import types

        # Newer AI Studio keys use AQ.… auth-key format. Prefer explicit
        # x-goog-api-key so the SDK does not treat the value like an OAuth token.
        http_options = types.HttpOptions(
            headers={"x-goog-api-key": api_key},
        )
        try:
            self._client = genai.Client(api_key=api_key, http_options=http_options)
        except TypeError:
            # Older google-genai builds may not accept http_options here.
            self._client = genai.Client(api_key=api_key)

    def generate_json(
        self,
        *,
        model: str,
        system_prompt: str,
        user_prompt: str,
        response_schema: type,
        evidence_images: list[tuple[bytes, str]] | None = None,
        timeout_s: float = 45.0,
    ) -> GeminiRawResponse:
        from google.genai import types

        parts: list[Any] = [types.Part.from_text(text=user_prompt)]
        for blob, mime in evidence_images or []:
            try:
                parts.append(types.Part.from_bytes(data=blob, mime_type=mime))
            except Exception as exc:  # noqa: BLE001
                raise GeminiClientError(
                    "UNSUPPORTED_EVIDENCE_IMAGE",
                    f"Evidence image could not be attached: {exc}",
                    retriable=False,
                ) from exc

        contents = [
            types.Content(role="user", parts=parts),
        ]
        config = types.GenerateContentConfig(
            system_instruction=system_prompt,
            response_mime_type="application/json",
            response_schema=response_schema,
            http_options=types.HttpOptions(timeout=int(timeout_s * 1000)),
        )
        try:
            response = self._client.models.generate_content(
                model=model,
                contents=contents,
                config=config,
            )
        except Exception as exc:  # noqa: BLE001
            raise _map_sdk_exception(exc) from exc

        # Safety / block
        finish = None
        safety_blocked = False
        try:
            cands = getattr(response, "candidates", None) or []
            if cands:
                finish = str(getattr(cands[0], "finish_reason", None) or "")
                if "SAFETY" in finish.upper():
                    safety_blocked = True
            prompt_feedback = getattr(response, "prompt_feedback", None)
            block = getattr(prompt_feedback, "block_reason", None) if prompt_feedback else None
            if block:
                safety_blocked = True
                finish = str(block)
        except Exception:  # noqa: BLE001
            pass

        if safety_blocked:
            raise GeminiClientError(
                "SAFETY_REFUSAL",
                f"Gemini safety refusal: {finish}",
                retriable=False,
            )

        text = getattr(response, "text", None)
        if not text and getattr(response, "parsed", None) is not None:
            parsed = response.parsed
            if hasattr(parsed, "model_dump_json"):
                text = parsed.model_dump_json()
            else:
                text = json.dumps(parsed, default=str)
        if not text:
            raise GeminiClientError(
                "MALFORMED_RESPONSE",
                "Gemini returned empty content",
                retriable=True,
            )

        model_version = None
        try:
            model_version = getattr(getattr(response, "model_version", None), None)  # type: ignore[arg-type]
        except Exception:  # noqa: BLE001
            model_version = None
        model_version = model_version or getattr(response, "model_version", None)

        return GeminiRawResponse(
            text=text,
            model_version=str(model_version) if model_version else None,
            finish_reason=finish,
            safety_blocked=False,
        )


def _map_sdk_exception(exc: Exception) -> GeminiClientError:
    msg = str(exc)
    low = msg.lower()
    name = type(exc).__name__.lower()
    if (
        "access_token_type_unsupported" in low
        or "invalid api key" in low
        or "api key not valid" in low
        or "permission_denied" in low
        or ("403" in low and "key" in low)
    ):
        return GeminiClientError("INVALID_API_KEY", msg, retriable=False)
    if (
        "api key" in low
        or "api_key" in low
        or "unauthenticated" in low
        or "401" in low
    ):
        return GeminiClientError("MISSING_API_KEY", msg, retriable=False)
    if "timeout" in low or "timed out" in low or "deadline" in low:
        return GeminiClientError("API_TIMEOUT", msg, retriable=True)
    if (
        "404" in low
        or "not_found" in low
        or "is not found" in low
        or "model_not_found" in low
    ):
        return GeminiClientError("MODEL_UNAVAILABLE", msg, retriable=False)
    # Do NOT match bare "rate" — it false-positives on "generateContent".
    if (
        "429" in low
        or "rate limit" in low
        or "rate_limit" in low
        or "quota" in low
        or "resource_exhausted" in low
    ):
        return GeminiClientError("RATE_LIMIT", msg, retriable=True)
    if "503" in low or "unavailable" in low or "outage" in low:
        return GeminiClientError("SERVICE_OUTAGE", msg, retriable=True)
    if "safety" in low or "blocked" in low:
        return GeminiClientError("SAFETY_REFUSAL", msg, retriable=False)
    if "image" in low and ("unsupported" in low or "invalid" in low):
        return GeminiClientError("UNSUPPORTED_EVIDENCE_IMAGE", msg, retriable=False)
    if "json" in low or "schema" in low or "parse" in low:
        return GeminiClientError("INVALID_STRUCTURED_OUTPUT", msg, retriable=True)
    if "connect" in low or "network" in name:
        return GeminiClientError("SERVICE_OUTAGE", msg, retriable=True)
    return GeminiClientError("GEMINI_ERROR", msg, retriable=True)


class MockGeminiTransport:
    """Test double that returns a fixed JSON payload or raises."""

    def __init__(
        self,
        *,
        response_text: str | None = None,
        error: GeminiClientError | None = None,
        model_version: str = "mock-1",
    ) -> None:
        self.response_text = response_text
        self.error = error
        self.model_version = model_version
        self.calls = 0

    def generate_json(
        self,
        *,
        model: str,
        system_prompt: str,
        user_prompt: str,
        response_schema: type,
        evidence_images: list[tuple[bytes, str]] | None = None,
        timeout_s: float = 45.0,
    ) -> GeminiRawResponse:
        self.calls += 1
        if self.error is not None:
            raise self.error
        if self.response_text is None:
            raise GeminiClientError("MALFORMED_RESPONSE", "mock has no response")
        return GeminiRawResponse(text=self.response_text, model_version=self.model_version)

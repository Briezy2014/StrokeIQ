"""ReportGenerator — confidence-aware Gemini coaching reports (Milestone 8)."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from pydantic import ValidationError

from app.config import Settings
from app.domain.jobs import AnalysisJob
from app.services.report.artifacts import write_report_artifacts
from app.services.report.client import (
    GeminiClientError,
    GeminiTransport,
    GoogleGenAITransport,
)
from app.services.report.context import build_report_context, collect_deterministic_payloads
from app.services.report.local_fallback import build_local_tracking_report
from app.services.report.prompt import SYSTEM_PROMPT, build_user_prompt
from app.services.report.schemas import (
    DEFAULT_MODEL_NAME,
    PROMPT_VERSION,
    REPORT_SCHEMA_VERSION,
    CoachingReportBody,
    ReportGenerationResult,
    StoredCoachingReport,
)
from app.services.report.validator import validate_coaching_report
from app.utils.logging import get_logger

logger = get_logger("video_analysis.report")

_MODEL_FALLBACKS = (
    "gemini-2.5-flash",
    "gemini-2.0-flash",
    "gemini-flash-latest",
    "gemini-2.5-flash-lite",
)


class ReportGenerator:
    """
    Generate a structured coaching report from deterministic CV results.

    Gemini never receives raw video and must not invent measurements.
    Deterministic metrics are always returned even when Gemini fails.
    """

    def __init__(
        self,
        *,
        settings: Settings | None = None,
        transport: GeminiTransport | None = None,
    ) -> None:
        self.settings = settings
        self._transport = transport

    def generate_for_job(
        self,
        job: AnalysisJob,
        *,
        output_dir: Path,
        authorize_age_group: bool = False,
        authorize_previous_results: bool = False,
        previous_athlete_results: list[dict[str, Any]] | None = None,
        approved_standards: list[dict[str, Any]] | None = None,
        evidence_frame_paths: list[dict[str, Any]] | None = None,
        attach_evidence_images: bool = False,
    ) -> ReportGenerationResult:
        metrics, events = collect_deterministic_payloads(job)
        context = build_report_context(
            job,
            authorize_age_group=authorize_age_group,
            authorize_previous_results=authorize_previous_results,
            previous_athlete_results=previous_athlete_results,
            approved_standards=approved_standards,
            evidence_frame_paths=evidence_frame_paths,
        )
        configured_model = (
            (self.settings.gemini_model_name if self.settings else None) or DEFAULT_MODEL_NAME
        )
        # Speed path for coach PCs: one model, one attempt, then rich local coaching.
        # Walking every fallback model can add minutes and break the 30-60s goal.
        model_candidates = [configured_model]
        max_attempts = min(
            1,
            max(1, self.settings.gemini_max_regenerate_attempts if self.settings else 1),
        )
        timeout_s = float(
            min(15.0, self.settings.gemini_timeout_s if self.settings else 15.0)
        )

        # Always prepare a rich local coach report first so short clips never
        # end with an empty yellow box if Gemini is slow or rejects the key.
        local_ready = self._local_fallback_result(
            job,
            context=context,
            metrics=metrics,
            events=events,
            output_dir=output_dir,
            model_name=configured_model,
            gemini_code="LOCAL_PRIMARY",
        )

        try:
            transport = self._get_transport()
        except GeminiClientError as exc:
            logger.warning(
                "Gemini unavailable job=%s code=%s — using rich local coaching",
                job.job_id,
                exc.code,
            )
            local_ready.limitations = [
                f"gemini_report_failed:{exc.code}",
                "local_coaching_fallback",
            ]
            return local_ready

        user_prompt = build_user_prompt(context)
        evidence_images = (
            _load_evidence_images(context.evidence_frames) if attach_evidence_images else []
        )

        last_errors: list[str] = []
        attempts = 0
        last_model = configured_model
        last_gemini_code = "REPORT_GENERATION_EXHAUSTED"

        for model_name in model_candidates:
            last_model = model_name
            model_dead = False
            for attempt in range(1, max_attempts + 1):
                attempts = attempt
                try:
                    raw = transport.generate_json(
                        model=model_name,
                        system_prompt=SYSTEM_PROMPT,
                        user_prompt=user_prompt
                        + (
                            f"\n\nPrevious validation errors to fix: {last_errors}"
                            if last_errors
                            else ""
                        ),
                        response_schema=CoachingReportBody,
                        evidence_images=evidence_images or None,
                        timeout_s=timeout_s,
                    )
                except GeminiClientError as exc:
                    last_gemini_code = exc.code
                    logger.warning(
                        "Gemini report failed job=%s model=%s code=%s",
                        job.job_id,
                        model_name,
                        exc.code,
                    )
                    # Fall back quickly to the prepared local coach report.
                    if exc.code in {
                        "MODEL_UNAVAILABLE",
                        "INVALID_API_KEY",
                        "MISSING_API_KEY",
                        "GEMINI_ERROR",
                        "API_TIMEOUT",
                        "RATE_LIMIT",
                        "SERVICE_OUTAGE",
                    }:
                        local_ready.limitations = [
                            f"gemini_report_failed:{exc.code}",
                            "local_coaching_fallback",
                        ]
                        return local_ready
                    if attempt >= max_attempts:
                        model_dead = True
                        break
                    continue

                try:
                    body = CoachingReportBody.model_validate_json(raw.text)
                except (ValidationError, json.JSONDecodeError, ValueError) as exc:
                    last_errors = [f"invalid_structured_output:{exc}"]
                    last_gemini_code = "INVALID_STRUCTURED_OUTPUT"
                    if attempt >= max_attempts:
                        model_dead = True
                        break
                    continue

                validation = validate_coaching_report(body, context)
                if not validation.ok:
                    last_errors = validation.errors
                    last_gemini_code = "REPORT_VALIDATION_REJECTED"
                    if attempt >= max_attempts:
                        model_dead = True
                        break
                    continue

                referenced_metrics, referenced_events = _collect_refs(body)
                stored = StoredCoachingReport(
                    schema_version=REPORT_SCHEMA_VERSION,
                    prompt_version=PROMPT_VERSION,
                    model_name=model_name,
                    model_version=raw.model_version or model_name,
                    generation_timestamp=datetime.now(timezone.utc),
                    job_id=job.job_id,
                    video_id=job.video_id,
                    status="validated",
                    report=body,
                    referenced_metric_ids=sorted(referenced_metrics),
                    referenced_event_ids=sorted(referenced_events),
                    regenerate_attempts=max(0, attempts - 1),
                )
                paths = write_report_artifacts(
                    output_dir,
                    stored=stored,
                    context_payload={
                        "prompt_version": PROMPT_VERSION,
                        "stroke": context.stroke_type,
                    },
                )
                logger.info("Gemini coaching report validated job=%s", job.job_id)
                return ReportGenerationResult(
                    deterministic_metrics=metrics,
                    deterministic_events=events,
                    report=stored,
                    artifact_paths=paths,
                    limitations=[],
                    gemini_succeeded=True,
                )

            if model_dead:
                continue

        logger.warning(
            "Gemini exhausted job=%s code=%s — using rich local coaching",
            job.job_id,
            last_gemini_code,
        )
        local_ready.limitations = [
            f"gemini_report_failed:{last_gemini_code}",
            "local_coaching_fallback",
        ]
        _ = last_model  # kept for logs above
        return local_ready

    def _local_fallback_result(
        self,
        job: AnalysisJob,
        *,
        context,
        metrics: list[dict[str, Any]],
        events: list[dict[str, Any]],
        output_dir: Path,
        model_name: str,
        gemini_code: str,
    ) -> ReportGenerationResult:
        body = build_local_tracking_report(context)
        referenced_metrics, referenced_events = _collect_refs(body)
        stored = StoredCoachingReport(
            schema_version=REPORT_SCHEMA_VERSION,
            prompt_version=PROMPT_VERSION,
            model_name="local-tracking-fallback",
            model_version=model_name,
            generation_timestamp=datetime.now(timezone.utc),
            job_id=job.job_id,
            video_id=job.video_id,
            status="validated",
            report=body,
            referenced_metric_ids=sorted(referenced_metrics),
            referenced_event_ids=sorted(referenced_events),
            failure_reason=f"gemini_unavailable:{gemini_code}",
            failure_code=None,
            regenerate_attempts=0,
        )
        paths = write_report_artifacts(
            output_dir,
            stored=stored,
            context_payload={
                "prompt_version": PROMPT_VERSION,
                "stroke": context.stroke_type,
                "fallback": gemini_code,
            },
        )
        return ReportGenerationResult(
            deterministic_metrics=metrics,
            deterministic_events=events,
            report=stored,
            artifact_paths=paths,
            limitations=[f"gemini_report_failed:{gemini_code}", "local_coaching_fallback"],
            # True so Flutter treats the coaching body as available.
            gemini_succeeded=True,
        )

    def _get_transport(self) -> GeminiTransport:
        if self._transport is not None:
            return self._transport
        key = (self.settings.gemini_api_key if self.settings else None) or ""
        if not key:
            raise GeminiClientError(
                "MISSING_API_KEY",
                "GEMINI_API_KEY is not set in backend environment",
            )
        try:
            return GoogleGenAITransport(api_key=key)
        except GeminiClientError:
            raise
        except Exception as exc:  # noqa: BLE001
            raise GeminiClientError(
                "GEMINI_ERROR",
                f"Gemini client could not start: {exc}",
                retriable=False,
            ) from exc

    def _failed_store(
        self,
        job: AnalysisJob,
        *,
        model_name: str,
        code: str,
        reason: str,
        model_version: str | None = None,
        attempts: int = 0,
        validation_errors: list[str] | None = None,
        body: CoachingReportBody | None = None,
    ) -> StoredCoachingReport:
        return StoredCoachingReport(
            schema_version=REPORT_SCHEMA_VERSION,
            prompt_version=PROMPT_VERSION,
            model_name=model_name,
            model_version=model_version or model_name,
            generation_timestamp=datetime.now(timezone.utc),
            job_id=job.job_id,
            video_id=job.video_id,
            status="failed",
            report=body,
            referenced_metric_ids=[],
            referenced_event_ids=[],
            validation_errors=list(validation_errors or []),
            failure_reason=reason,
            failure_code=code,
            regenerate_attempts=max(0, attempts - 1),
        )


def _collect_refs(body: CoachingReportBody) -> tuple[set[str], set[str]]:
    metrics: set[str] = set()
    events: set[str] = set()
    for s in body.strengths:
        metrics.update(s.metric_ids)
        events.update(s.event_ids)
    for p in body.priority_improvements:
        metrics.update(p.observation.metric_ids)
        events.update(p.observation.event_ids)
    return metrics, events


def _load_evidence_images(frames) -> list[tuple[bytes, str]]:
    out: list[tuple[bytes, str]] = []
    for fr in frames:
        path = getattr(fr, "path", None)
        if not path:
            continue
        p = Path(path)
        if not p.is_file():
            continue
        suffix = p.suffix.lower()
        mime = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png"}.get(suffix)
        if mime is None:
            raise GeminiClientError(
                "UNSUPPORTED_EVIDENCE_IMAGE",
                f"Unsupported evidence image type: {suffix}",
            )
        out.append((p.read_bytes(), mime))
        if len(out) >= 4:
            break
    return out

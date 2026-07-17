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
        model_name = (
            (self.settings.gemini_model_name if self.settings else None) or DEFAULT_MODEL_NAME
        )
        max_attempts = (
            self.settings.gemini_max_regenerate_attempts if self.settings else 2
        )

        try:
            transport = self._get_transport()
        except GeminiClientError as exc:
            stored = self._failed_store(
                job,
                model_name=model_name,
                code=exc.code,
                reason=exc.message,
            )
            paths = write_report_artifacts(
                output_dir,
                stored=stored,
                context_payload={"job_id": job.job_id, "failure": exc.code},
            )
            return ReportGenerationResult(
                deterministic_metrics=metrics,
                deterministic_events=events,
                report=stored,
                artifact_paths=paths,
                limitations=[f"gemini_report_failed:{exc.code}"],
                gemini_succeeded=False,
            )

        user_prompt = build_user_prompt(context)
        evidence_images = (
            _load_evidence_images(context.evidence_frames) if attach_evidence_images else []
        )

        last_errors: list[str] = []
        attempts = 0
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
                    timeout_s=float(
                        self.settings.gemini_timeout_s if self.settings else 45.0
                    ),
                )
            except GeminiClientError as exc:
                stored = self._failed_store(
                    job,
                    model_name=model_name,
                    code=exc.code,
                    reason=exc.message,
                    attempts=attempts,
                )
                paths = write_report_artifacts(output_dir, stored=stored)
                logger.warning(
                    "Gemini report failed job=%s code=%s", job.job_id, exc.code
                )
                return ReportGenerationResult(
                    deterministic_metrics=metrics,
                    deterministic_events=events,
                    report=stored,
                    artifact_paths=paths,
                    limitations=[f"gemini_report_failed:{exc.code}"],
                    gemini_succeeded=False,
                )

            try:
                body = CoachingReportBody.model_validate_json(raw.text)
            except (ValidationError, json.JSONDecodeError, ValueError) as exc:
                last_errors = [f"invalid_structured_output:{exc}"]
                if attempt >= max_attempts:
                    stored = self._failed_store(
                        job,
                        model_name=model_name,
                        model_version=raw.model_version,
                        code="INVALID_STRUCTURED_OUTPUT",
                        reason=str(exc),
                        attempts=attempts,
                        validation_errors=last_errors,
                    )
                    paths = write_report_artifacts(output_dir, stored=stored)
                    return ReportGenerationResult(
                        deterministic_metrics=metrics,
                        deterministic_events=events,
                        report=stored,
                        artifact_paths=paths,
                        limitations=["gemini_report_failed:INVALID_STRUCTURED_OUTPUT"],
                        gemini_succeeded=False,
                    )
                continue

            validation = validate_coaching_report(body, context)
            if not validation.ok:
                last_errors = validation.errors
                if attempt >= max_attempts:
                    stored = self._failed_store(
                        job,
                        model_name=model_name,
                        model_version=raw.model_version,
                        code="REPORT_VALIDATION_REJECTED",
                        reason="coaching_report_failed_validation",
                        attempts=attempts,
                        validation_errors=validation.errors,
                        body=body,
                    )
                    paths = write_report_artifacts(output_dir, stored=stored)
                    return ReportGenerationResult(
                        deterministic_metrics=metrics,
                        deterministic_events=events,
                        report=stored,
                        artifact_paths=paths,
                        limitations=["gemini_report_failed:REPORT_VALIDATION_REJECTED"],
                        gemini_succeeded=False,
                    )
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
                regenerate_attempts=attempts - 1,
            )
            paths = write_report_artifacts(
                output_dir,
                stored=stored,
                context_payload={"prompt_version": PROMPT_VERSION, "stroke": context.stroke_type},
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

        stored = self._failed_store(
            job,
            model_name=model_name,
            code="REPORT_GENERATION_EXHAUSTED",
            reason="exhausted_regenerate_attempts",
            attempts=attempts,
            validation_errors=last_errors,
        )
        paths = write_report_artifacts(output_dir, stored=stored)
        return ReportGenerationResult(
            deterministic_metrics=metrics,
            deterministic_events=events,
            report=stored,
            artifact_paths=paths,
            limitations=["gemini_report_failed:REPORT_GENERATION_EXHAUSTED"],
            gemini_succeeded=False,
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
        return GoogleGenAITransport(api_key=key)

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

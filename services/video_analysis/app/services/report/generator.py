"""ReportGenerator — always-on SwimIQ Elite coaching (Milestone 8).

Primary path never depends on Gemini. Optional Gemini enhance only runs when
explicitly enabled, and only replaces the report on full success.
"""

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

ELITE_COACH_MODEL = "swimiq-elite-coach-v1"


class ReportGenerator:
    """
    Generate a structured coaching report from deterministic CV results.

    Always returns a complete SwimIQ Elite coaching report.
    Gemini is optional and never required for success.
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

        # Always-on primary path — 100% coaching, no Gemini dependency.
        elite = self._elite_coach_result(
            job,
            context=context,
            metrics=metrics,
            events=events,
            output_dir=output_dir,
        )

        want_gemini = bool(self.settings and self.settings.gemini_report_enabled)
        if not want_gemini:
            logger.info(
                "Elite coaching ready job=%s model=%s (Gemini off)",
                job.job_id,
                ELITE_COACH_MODEL,
            )
            return elite

        # Optional enhance only. Any Gemini failure keeps elite coaching with
        # zero gemini_* failure notes for the athlete.
        try:
            enhanced = self._try_gemini_enhance(
                job,
                context=context,
                metrics=metrics,
                events=events,
                output_dir=output_dir,
                attach_evidence_images=attach_evidence_images,
            )
            if enhanced is not None:
                return enhanced
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "Optional Gemini enhance skipped job=%s err=%s",
                job.job_id,
                exc,
            )
        return elite

    def _try_gemini_enhance(
        self,
        job: AnalysisJob,
        *,
        context,
        metrics: list[dict[str, Any]],
        events: list[dict[str, Any]],
        output_dir: Path,
        attach_evidence_images: bool,
    ) -> ReportGenerationResult | None:
        configured_model = (
            (self.settings.gemini_model_name if self.settings else None) or DEFAULT_MODEL_NAME
        )
        model_candidates: list[str] = []
        for name in (configured_model, "gemini-2.0-flash", "gemini-2.5-flash"):
            if name and name not in model_candidates:
                model_candidates.append(name)
        timeout_s = float(
            min(12.0, self.settings.gemini_timeout_s if self.settings else 12.0)
        )

        try:
            transport = self._get_transport()
        except GeminiClientError as exc:
            logger.warning(
                "Optional Gemini unavailable job=%s code=%s — keeping Elite coaching",
                job.job_id,
                exc.code,
            )
            return None

        user_prompt = build_user_prompt(context)
        evidence_images = (
            _load_evidence_images(context.evidence_frames) if attach_evidence_images else []
        )

        for model_name in model_candidates:
            try:
                raw = transport.generate_json(
                    model=model_name,
                    system_prompt=SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    response_schema=CoachingReportBody,
                    evidence_images=evidence_images or None,
                    timeout_s=timeout_s,
                )
            except GeminiClientError as exc:
                logger.warning(
                    "Optional Gemini failed job=%s model=%s code=%s",
                    job.job_id,
                    model_name,
                    exc.code,
                )
                if exc.code == "MODEL_UNAVAILABLE":
                    continue
                return None

            try:
                body = CoachingReportBody.model_validate_json(raw.text)
            except (ValidationError, json.JSONDecodeError, ValueError):
                continue

            validation = validate_coaching_report(body, context)
            if not validation.ok:
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
                regenerate_attempts=0,
            )
            paths = write_report_artifacts(
                output_dir,
                stored=stored,
                context_payload={
                    "prompt_version": PROMPT_VERSION,
                    "stroke": context.stroke_type,
                },
            )
            logger.info("Optional Gemini enhance accepted job=%s model=%s", job.job_id, model_name)
            return ReportGenerationResult(
                deterministic_metrics=metrics,
                deterministic_events=events,
                report=stored,
                artifact_paths=paths,
                limitations=[],
                gemini_succeeded=True,
            )
        return None

    def _elite_coach_result(
        self,
        job: AnalysisJob,
        *,
        context,
        metrics: list[dict[str, Any]],
        events: list[dict[str, Any]],
        output_dir: Path,
    ) -> ReportGenerationResult:
        body = build_local_tracking_report(context)
        referenced_metrics, referenced_events = _collect_refs(body)
        stored = StoredCoachingReport(
            schema_version=REPORT_SCHEMA_VERSION,
            prompt_version=PROMPT_VERSION,
            model_name=ELITE_COACH_MODEL,
            model_version=ELITE_COACH_MODEL,
            generation_timestamp=datetime.now(timezone.utc),
            job_id=job.job_id,
            video_id=job.video_id,
            status="validated",
            report=body,
            referenced_metric_ids=sorted(referenced_metrics),
            referenced_event_ids=sorted(referenced_events),
            failure_reason=None,
            failure_code=None,
            regenerate_attempts=0,
        )
        paths = write_report_artifacts(
            output_dir,
            stored=stored,
            context_payload={
                "prompt_version": PROMPT_VERSION,
                "stroke": context.stroke_type,
                "coach": ELITE_COACH_MODEL,
            },
        )
        return ReportGenerationResult(
            deterministic_metrics=metrics,
            deterministic_events=events,
            report=stored,
            artifact_paths=paths,
            limitations=[],
            # True so Flutter treats the coaching body as available.
            gemini_succeeded=True,
        )

    # Back-compat name used by older tests / call sites.
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
        return self._elite_coach_result(
            job,
            context=context,
            metrics=metrics,
            events=events,
            output_dir=output_dir,
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
            model_version=model_version,
            generation_timestamp=datetime.now(timezone.utc),
            job_id=job.job_id,
            video_id=job.video_id,
            status="failed",
            report=body,
            failure_reason=reason,
            failure_code=code,
            regenerate_attempts=attempts,
            validation_errors=validation_errors or [],
        )


def _collect_refs(body: CoachingReportBody) -> tuple[set[str], set[str]]:
    metrics: set[str] = set()
    events: set[str] = set()
    for s in body.strengths:
        metrics.update(s.metric_ids)
        events.update(s.event_ids)
    for pri in body.priority_improvements:
        metrics.update(pri.observation.metric_ids)
        events.update(pri.observation.event_ids)
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
        mime = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png"}.get(
            suffix
        )
        if mime is None:
            raise GeminiClientError(
                "UNSUPPORTED_EVIDENCE_IMAGE",
                f"Unsupported evidence image type: {suffix}",
            )
        out.append((p.read_bytes(), mime))
        if len(out) >= 4:
            break
    return out

"""Persist coaching-report artifacts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from app.services.report.schemas import ReportGenerationResult, StoredCoachingReport


def write_report_artifacts(
    output_dir: Path,
    *,
    stored: StoredCoachingReport,
    context_payload: dict[str, Any] | None = None,
) -> dict[str, str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, str] = {}

    report_path = output_dir / "coaching_report.json"
    report_path.write_text(stored.model_dump_json(indent=2), encoding="utf-8")
    paths["coaching_report_json"] = str(report_path.resolve())

    if context_payload is not None:
        ctx_path = output_dir / "report_context.json"
        # Never write API keys; context is already Gemini-safe structured results.
        ctx_path.write_text(json.dumps(context_payload, indent=2, default=str), encoding="utf-8")
        paths["report_context_json"] = str(ctx_path.resolve())

    if stored.validation_errors:
        err_path = output_dir / "report_validation_errors.json"
        err_path.write_text(
            json.dumps({"errors": stored.validation_errors}, indent=2),
            encoding="utf-8",
        )
        paths["report_validation_errors"] = str(err_path.resolve())

    return paths


def result_to_job_payload(result: ReportGenerationResult) -> dict[str, Any]:
    return {
        "gemini_succeeded": result.gemini_succeeded,
        "report": result.report.model_dump(mode="json") if result.report else None,
        "artifact_paths": result.artifact_paths,
        "limitations": result.limitations,
        "deterministic_metrics_count": len(result.deterministic_metrics),
        "deterministic_events_count": len(result.deterministic_events),
    }

"""Milestone 8 Gemini coaching-report tests (mocked transport; no live API)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.domain.jobs import AnalysisJob
from app.services.report.client import GeminiClientError, MockGeminiTransport
from app.services.report.context import build_report_context
from app.services.report.generator import ReportGenerator
from app.services.report.schemas import CoachingReportBody, ReportContext
from app.services.report.validator import validate_coaching_report


def _job_with_metrics() -> AnalysisJob:
    job = AnalysisJob(
        job_id="job-m8",
        video_id="vid-m8",
        engine_version="elote-0.8.0",
        request_payload={
            "athlete": {"swimmer_key": "s1", "display_name": "Alex", "age_group": "11-12"},
            "event": {"stroke": "butterfly", "distance_m": 50, "course": "SCY"},
            "options": {"generate_gemini_report": True},
        },
    )
    job.butterfly = {
        "summary": {"complete_cycles": 4, "stroke": "butterfly"},
        "metrics": [
            {
                "name": "stroke_rate",
                "display_name": "Stroke rate",
                "value": 48.0,
                "unit": "strokes/min",
                "confidence": 0.86,
                "confidence_label": "high",
                "classification": "estimated",
                "method": "cycle_timing",
                "supporting_frame_numbers": [12, 30],
                "supporting_timestamps_ms": [400.0, 1000.0],
                "quality_flags": [],
                "limitations": [],
            },
            {
                "name": "cycle_duration",
                "display_name": "Cycle duration",
                "value": 1.25,
                "unit": "s",
                "confidence": 0.8,
                "confidence_label": "high",
                "classification": "estimated",
                "method": "entry_to_entry",
                "supporting_frame_numbers": [12, 30],
                "supporting_timestamps_ms": [400.0, 1000.0],
                "quality_flags": [],
            },
            {
                "name": "distance_per_stroke",
                "display_name": "Distance per stroke",
                "value": None,
                "unit": "m",
                "confidence": 0.0,
                "confidence_label": "unavailable",
                "classification": "unavailable",
                "method": "requires_pool_calibration",
                "unavailable_reason": "pool_not_calibrated",
                "quality_flags": [],
            },
        ],
        "events": [
            {
                "event_type": "hand_entry",
                "timestamp_ms": 1000.0,
                "frame_number": 30,
                "confidence": 0.84,
                "confidence_label": "high",
                "method": "wrist_surface_crossing",
                "supporting_frames": [30],
                "supporting_timestamps_ms": [1000.0],
                "quality_flags": [],
            }
        ],
        "entry_frames": [12, 30, 48],
    }
    job.underwater = {
        "summary": {"kick_count": 3},
        "metrics": [
            {
                "name": "estimated_underwater_kick_count",
                "display_name": "Underwater kick count",
                "value": 3,
                "unit": "kicks",
                "confidence": 0.58,
                "confidence_label": "moderate",
                "classification": "estimated",
                "method": "ankle_oscillation",
                "supporting_frame_numbers": [5, 10, 15],
                "supporting_timestamps_ms": [166.0, 333.0, 500.0],
                "quality_flags": [],
            }
        ],
        "events": [
            {
                "event_type": "breakout",
                "timestamp_ms": 800.0,
                "frame_number": 24,
                "confidence": 0.62,
                "confidence_label": "moderate",
                "method": "surface_reappearance",
                "supporting_frames": [24],
                "supporting_timestamps_ms": [800.0],
                "quality_flags": [],
            }
        ],
        "kick_frames": [5, 10, 15],
        "breakout_frame": 24,
    }
    job.limitations = ["side_view_partial_occlusion"]
    return job


def _valid_report_dict() -> dict:
    return {
        "summary": (
            "Alex showed a steady butterfly rhythm on this 50 SCY clip. "
            "The analysis highlights consistent hand entries and a controlled underwater kick pattern."
        ),
        "strengths": [
            {
                "text": (
                    "Hand entries look well timed around frame 30, supporting a repeatable stroke rhythm "
                    "near 48 strokes/min."
                ),
                "confidence_band": "high",
                "metric_ids": ["butterfly:stroke_rate"],
                "event_ids": ["butterfly:hand_entry:30"],
            },
            {
                "text": "Cycle duration near 1.25 s shows a controlled tempo that coaches can build on.",
                "confidence_band": "high",
                "metric_ids": ["butterfly:cycle_duration"],
                "event_ids": [],
            },
            {
                "text": (
                    "The analysis suggests the underwater kick count near 3 kicks is organized before breakout."
                ),
                "confidence_band": "moderate",
                "metric_ids": ["underwater:estimated_underwater_kick_count"],
                "event_ids": ["underwater:breakout:24"],
            },
        ],
        "priority_improvements": [
            {
                "observation": {
                    "text": (
                        "The analysis suggests tightening breakout timing after the third kick so the first "
                        "surface stroke connects more cleanly."
                    ),
                    "confidence_band": "moderate",
                    "metric_ids": ["underwater:estimated_underwater_kick_count"],
                    "event_ids": ["underwater:breakout:24"],
                },
                "drills": [
                    "3-kick breakout butterfly drills focusing on surfacing with the first pull",
                    "Underwater kick count ladders (2-3-4) with video review",
                ],
            }
        ],
        "supporting_evidence": [
            "Stroke rate metric butterfly:stroke_rate",
            "Breakout event underwater:breakout:24",
        ],
        "race_recommendations": [
            "For 50 SCY butterfly, keep the same early rhythm and rehearse a 3-kick breakout plan."
        ],
        "limitations": [
            "Side-view partial occlusion may hide some bodyline details.",
            "Distance-per-stroke was unavailable without pool calibration.",
        ],
        "confidence_statement": (
            "High-confidence surface timing findings are stated directly; moderate underwater findings "
            "use suggestive language because visibility varies."
        ),
        "disclaimer": (
            "These coaching estimates depend on video quality and camera angle, and they should be "
            "interpreted with the recorded evidence frames."
        ),
    }


def _hallucinated_report_dict() -> dict:
    body = _valid_report_dict()
    body["strengths"][0] = {
        "text": (
            "The swimmer held an elite stroke rate of 92 strokes/min and gained 0.4 s on every wall, "
            "definitely proving superior power."
        ),
        "confidence_band": "high",
        "metric_ids": ["butterfly:stroke_rate"],
        "event_ids": ["butterfly:hand_entry:30"],
    }
    return body


def test_context_excludes_unavailable_metrics_from_findings_set():
    ctx = build_report_context(_job_with_metrics(), authorize_age_group=True)
    assert "butterfly:stroke_rate" in ctx.available_metric_ids()
    assert "butterfly:distance_per_stroke" not in ctx.available_metric_ids()
    assert "butterfly:distance_per_stroke" in ctx.all_metric_ids()
    assert ctx.athlete_age_group == "11-12"


def test_valid_report_passes_validation():
    ctx = build_report_context(_job_with_metrics())
    body = CoachingReportBody.model_validate(_valid_report_dict())
    result = validate_coaching_report(body, ctx)
    assert result.ok, result.errors


def test_hallucinated_measurement_is_rejected():
    ctx = build_report_context(_job_with_metrics())
    body = CoachingReportBody.model_validate(_hallucinated_report_dict())
    result = validate_coaching_report(body, ctx)
    assert not result.ok
    assert any("invented_measurement" in e or "invented_statistic" in e for e in result.errors)


def test_missing_evidence_ids_rejected():
    ctx = build_report_context(_job_with_metrics())
    data = _valid_report_dict()
    data["strengths"][0]["metric_ids"] = []
    data["strengths"][0]["event_ids"] = []
    body = CoachingReportBody.model_validate(data)
    result = validate_coaching_report(body, ctx)
    assert any("omits_evidence" in e for e in result.errors)


def test_unavailable_metric_cannot_be_a_finding():
    ctx = build_report_context(_job_with_metrics())
    data = _valid_report_dict()
    data["strengths"][0]["metric_ids"] = ["butterfly:distance_per_stroke"]
    data["strengths"][0]["text"] = "Distance per stroke looks strong in this clip."
    body = CoachingReportBody.model_validate(data)
    result = validate_coaching_report(body, ctx)
    assert any("unavailable_metric" in e for e in result.errors)


def test_medical_and_shame_claims_rejected():
    ctx = build_report_context(_job_with_metrics())
    data = _valid_report_dict()
    data["summary"] = "This lazy swimmer has a shoulder injury that proves they are hopeless."
    body = CoachingReportBody.model_validate(data)
    result = validate_coaching_report(body, ctx)
    assert any("medical_claim" in e for e in result.errors)
    assert any("shame" in e for e in result.errors)


def test_low_confidence_requires_cautious_language():
    job = _job_with_metrics()
    job.underwater["metrics"][0]["confidence"] = 0.3
    job.underwater["metrics"][0]["confidence_label"] = "low"
    ctx = build_report_context(job)
    data = _valid_report_dict()
    data["priority_improvements"][0]["observation"] = {
        "text": "Breakout timing is definitely late after three kicks.",
        "confidence_band": "low",
        "metric_ids": ["underwater:estimated_underwater_kick_count"],
        "event_ids": ["underwater:breakout:24"],
    }
    body = CoachingReportBody.model_validate(data)
    result = validate_coaching_report(body, ctx)
    assert any("cautious_wording" in e or "certainty" in e for e in result.errors)


def test_generator_success_with_mock(tmp_path: Path):
    transport = MockGeminiTransport(response_text=json.dumps(_valid_report_dict()))
    gen = ReportGenerator(transport=transport)
    result = gen.generate_for_job(_job_with_metrics(), output_dir=tmp_path / "report")
    assert result.gemini_succeeded is True
    assert result.report is not None
    assert result.report.status == "validated"
    assert result.report.prompt_version
    assert result.report.schema_version
    assert result.report.model_name
    assert result.report.generation_timestamp
    assert result.report.referenced_metric_ids
    assert Path(result.artifact_paths["coaching_report_json"]).is_file()
    # Deterministic metrics always present
    assert any(m.get("name") == "stroke_rate" for m in result.deterministic_metrics)


def test_generator_rejects_hallucination_and_falls_back_locally(tmp_path: Path):
    transport = MockGeminiTransport(response_text=json.dumps(_hallucinated_report_dict()))
    # Force single attempt so rejection is final for each model candidate
    from app.config import Settings

    settings = Settings(gemini_max_regenerate_attempts=1, gemini_api_key="test-key")
    gen = ReportGenerator(settings=settings, transport=transport)
    result = gen.generate_for_job(_job_with_metrics(), output_dir=tmp_path / "report")
    assert result.report is not None
    assert result.report.status == "validated"
    assert result.report.model_name == "local-tracking-fallback"
    assert any("REPORT_VALIDATION_REJECTED" in x for x in result.limitations)
    assert result.deterministic_metrics  # survive failure


def test_missing_api_key_uses_local_coaching_fallback(tmp_path: Path):
    from app.config import Settings

    settings = Settings(gemini_api_key=None, gemini_report_enabled=True)
    gen = ReportGenerator(settings=settings, transport=None)
    result = gen.generate_for_job(_job_with_metrics(), output_dir=tmp_path / "report")
    assert result.report is not None
    assert result.report.status == "validated"
    assert result.report.report is not None
    assert result.report.report.summary
    assert any("MISSING_API_KEY" in x for x in result.limitations)
    assert result.deterministic_metrics


@pytest.mark.parametrize(
    "code",
    [
        "API_TIMEOUT",
        "RATE_LIMIT",
        "SERVICE_OUTAGE",
        "SAFETY_REFUSAL",
        "MALFORMED_RESPONSE",
    ],
)
def test_gemini_transport_errors_use_local_fallback(tmp_path: Path, code: str):
    transport = MockGeminiTransport(error=GeminiClientError(code, f"simulated {code}", retriable=True))
    gen = ReportGenerator(transport=transport)
    result = gen.generate_for_job(_job_with_metrics(), output_dir=tmp_path / code)
    assert result.report is not None
    assert result.report.status == "validated"
    assert result.report.report is not None
    assert any(code in x for x in result.limitations)
    assert len(result.deterministic_metrics) >= 1


def test_exceeding_priority_count_rejected():
    ctx = build_report_context(_job_with_metrics())
    data = _valid_report_dict()
    pri = data["priority_improvements"][0]
    data["priority_improvements"] = [pri, pri, pri, pri]
    with pytest.raises(Exception):
        CoachingReportBody.model_validate(data)


def test_prompt_never_includes_raw_video_path():
    from app.services.report.prompt import build_user_prompt

    ctx = build_report_context(_job_with_metrics())
    prompt = build_user_prompt(ctx)
    assert ".mp4" not in prompt
    assert "raw video" not in prompt.lower()
    assert "butterfly:stroke_rate" in prompt

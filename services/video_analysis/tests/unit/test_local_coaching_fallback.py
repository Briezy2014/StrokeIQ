"""Rich local coaching fallback must always produce a full coach report."""

from __future__ import annotations

from app.domain.jobs import AnalysisJob, new_job_id
from app.services.report.context import build_report_context
from app.services.report.local_fallback import build_local_tracking_report
from app.services.report.validator import validate_coaching_report


def _tracking_job(stroke: str = "butterfly") -> AnalysisJob:
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-local",
        engine_version="elite-0.9.0",
        request_payload={
            "event": {"stroke": stroke, "distance_m": 50, "course": "SCY"},
            "athlete": {"display_name": "Aspyn"},
        },
    )
    job.tracking = {
        "target": {
            "track_id": "t1",
            "target_identity_confidence": 0.7,
            "observations": [
                {"frame_number": 3, "timestamp_ms": 100, "confidence": 0.8},
                {"frame_number": 30, "timestamp_ms": 1000, "confidence": 0.7},
            ],
        },
        "quality_summary": {
            "target_coverage": 0.55,
            "processed_frames": 40,
            "frames_with_detections": 28,
        },
    }
    return job


def test_local_fallback_has_full_coach_breakdown():
    ctx = build_report_context(_tracking_job("butterfly"))
    body = build_local_tracking_report(ctx)
    assert len(body.summary) >= 20
    assert 1 <= len(body.strengths) <= 3
    assert 1 <= len(body.priority_improvements) <= 3
    assert body.race_recommendations
    assert all(1 <= len(p.drills) <= 2 for p in body.priority_improvements)
    result = validate_coaching_report(body, ctx)
    assert result.ok, result.errors


def test_local_fallback_freestyle_next_race_cues():
    ctx = build_report_context(_tracking_job("freestyle"))
    body = build_local_tracking_report(ctx)
    joined = " ".join(body.race_recommendations).lower()
    assert "race cue" in joined or "cue" in joined
    assert validate_coaching_report(body, ctx).ok

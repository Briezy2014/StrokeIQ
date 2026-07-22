"""Local coaching must be clear swimmer-speak."""

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


def _blob(body) -> str:
    return " ".join(
        [body.summary]
        + [s.text for s in body.strengths]
        + [p.observation.text for p in body.priority_improvements]
        + [d for p in body.priority_improvements for d in p.drills]
        + list(body.race_recommendations)
        + list(body.limitations)
    ).lower()


def test_local_fallback_is_swimmer_speak():
    ctx = build_report_context(_tracking_job("butterfly"))
    body = build_local_tracking_report(ctx)
    blob = _blob(body)
    assert "frame" not in blob
    assert "the available frames may indicate" not in blob
    assert "local coaching" not in blob
    assert "gemini" not in blob
    assert "pro:" not in blob
    assert "con:" not in blob
    assert "dryland" in blob
    assert "race cue" in blob
    assert "aspyn" in body.summary.lower()
    assert "estimate, not a promise" not in blob
    assert "not a guarantee" not in blob
    assert "limitations" not in blob
    assert "that's your potential" in blob or "your potential" in blob
    assert 1 <= len(body.strengths) <= 2
    assert 1 <= len(body.priority_improvements) <= 2
    assert validate_coaching_report(body, ctx).ok, validate_coaching_report(body, ctx).errors


def test_local_fallback_freestyle_time_drop():
    ctx = build_report_context(_tracking_job("freestyle"))
    body = build_local_tracking_report(ctx)
    joined = " ".join(body.race_recommendations).lower()
    assert "seconds" in joined
    assert "your potential" in joined
    assert "not a promise" not in joined
    assert validate_coaching_report(body, ctx).ok

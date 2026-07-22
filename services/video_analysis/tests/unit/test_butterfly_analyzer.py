"""Milestone 5 butterfly surface-stroke analyzer tests (manually labeled fixtures)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.services.butterfly import ButterflyAnalyzer
from app.services.butterfly.types import MetricValue

FIX = Path(__file__).resolve().parents[1] / "fixtures" / "butterfly"
ENTRY_TOLERANCE_FRAMES = 3


def _load(name: str) -> tuple[list[dict], dict]:
    poses = json.loads((FIX / f"{name}.smoothed_pose.json").read_text())["poses"]
    labels = json.loads((FIX / f"{name}.labels.json").read_text())
    return poses, labels


def _analyze(name: str, tmp_path: Path, **kwargs):
    poses, labels = _load(name)
    view = kwargs.pop("view_hint", labels.get("view", "side"))
    stroke = kwargs.pop("stroke_hint", "butterfly")
    analyzer = ButterflyAnalyzer()
    result = analyzer.analyze(
        poses,
        job_id=f"test-{name}",
        video_id=name,
        output_dir=tmp_path / name,
        stroke_hint=stroke,
        view_hint=view,
        **kwargs,
    )
    return result, labels


def _entry_errors(predicted: list[int], expected: list[int]) -> list[int]:
    errs = []
    for e in expected:
        if not predicted:
            errs.append(10**9)
        else:
            errs.append(min(abs(p - e) for p in predicted))
    return errs


def _metric(result, name: str) -> dict:
    for m in result.metrics:
        if m["name"] == name:
            return m
    raise KeyError(name)


def test_clean_side_view_butterfly(tmp_path):
    result, labels = _analyze("clean_side_view", tmp_path, view_hint="side")
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    assert result.summary["stroke_count"] == labels["n_cycles"]
    rate = _metric(result, "average_stroke_rate")
    assert rate["classification"] == "measured"
    assert rate["value"] is not None
    assert 40.0 <= float(rate["value"]) <= 60.0
    assert Path(result.artifact_paths["cycle_boundaries_json"]).is_file()
    assert Path(result.artifact_paths["chart_wrist_trajectories"]).is_file()


def test_diagonal_view(tmp_path):
    result, labels = _analyze("diagonal_view", tmp_path, view_hint="diagonal_side")
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    assert result.summary["stroke_count"] == labels["n_cycles"]


def test_breathing_every_cycle(tmp_path):
    result, labels = _analyze("breath_every_cycle", tmp_path)
    breath = _metric(result, "breathing_event_estimate")
    assert breath["classification"] == "estimated"
    assert breath["value"] is not None
    assert int(breath["value"]) >= labels["n_cycles"] - 1
    assert breath["confidence"] > 0
    timing = _metric(result, "breath_timing_within_stroke_cycle")
    assert timing["value"] is not None


def test_breathing_every_second_cycle(tmp_path):
    result, labels = _analyze("breath_every_second_cycle", tmp_path)
    breath = _metric(result, "breathing_event_estimate")
    # Every second cycle ⇒ roughly half as many breaths as cycles
    assert breath["value"] is not None
    assert int(breath["value"]) <= labels["n_cycles"]
    assert int(breath["value"]) >= max(1, labels["n_cycles"] // 2 - 1)


def test_missing_wrist_frames(tmp_path):
    result, labels = _analyze("missing_wrist_frames", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    assert result.summary["stroke_count"] == labels["n_cycles"]


def test_splash_obscured_entry(tmp_path):
    result, labels = _analyze("splash_obscured_entry", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    # Confidence should still be scored; splash may add quality flags on some events
    assert any(e["event_type"] == "hand_entry" for e in result.events)


def test_partial_stroke_at_beginning(tmp_path):
    result, labels = _analyze("partial_start", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    assert result.summary["stroke_count"] == labels["n_cycles"]


def test_partial_stroke_at_end(tmp_path):
    result, labels = _analyze("partial_end", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    assert result.summary["stroke_count"] == labels["n_cycles"]


def test_fewer_than_two_complete_cycles(tmp_path):
    result, labels = _analyze("fewer_than_two_cycles", tmp_path)
    assert result.summary["stroke_count"] == 1
    rate = _metric(result, "average_stroke_rate")
    assert rate["value"] is None
    assert rate["classification"] == "unavailable"
    assert rate["unavailable_reason"] == "fewer_than_two_complete_cycles"
    var = _metric(result, "cycle_to_cycle_timing_variability")
    assert var["value"] is None


def test_incorrect_stroke_type(tmp_path):
    result, _ = _analyze("clean_side_view", tmp_path, stroke_hint="freestyle")
    rate = _metric(result, "average_stroke_rate")
    assert rate["value"] is None
    assert rate["classification"] == "unavailable"
    assert "incorrect_stroke_type" in (rate["unavailable_reason"] or "")
    # No fabricated stroke rate
    assert all(
        m["value"] is None
        for m in result.metrics
        if m["name"] in {"stroke_count", "average_stroke_rate", "complete_stroke_cycle_count"}
    )


def test_variable_frame_rate(tmp_path):
    result, labels = _analyze("variable_frame_rate", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    assert max(errs) <= ENTRY_TOLERANCE_FRAMES
    dur = _metric(result, "average_cycle_duration")
    assert dur["value"] is not None
    # Duration must come from timestamps, not frame counts alone
    assert 1.0 <= float(dur["value"]) <= 1.5


def test_metric_schema_fields(tmp_path):
    result, _ = _analyze("clean_side_view", tmp_path)
    required = {
        "value",
        "unit",
        "confidence",
        "confidence_label",
        "method",
        "supporting_timestamps_ms",
        "supporting_frame_numbers",
        "quality_flags",
        "classification",
    }
    for m in result.metrics:
        assert required.issubset(m.keys())
        if m["value"] is None:
            assert m["unavailable_reason"]
            assert m["classification"] == "unavailable"


def test_no_distance_per_stroke_without_calibration(tmp_path):
    result, _ = _analyze("clean_side_view", tmp_path, pool_distance_calibrated=False)
    dps = _metric(result, "distance_per_stroke")
    assert dps["value"] is None
    assert "calibration" in (dps["unavailable_reason"] or "")


def test_no_exact_angles_fabricated(tmp_path):
    result, _ = _analyze("clean_side_view", tmp_path)
    for name in ("exact_elbow_angle", "exact_shoulder_angle"):
        m = _metric(result, name)
        assert m["value"] is None
        assert m["classification"] == "unavailable"


def test_events_include_cycle_and_breath(tmp_path):
    result, _ = _analyze("breath_every_cycle", tmp_path)
    types = {e["event_type"] for e in result.events}
    assert {"cycle_start", "cycle_end", "hand_entry", "breath_estimate"} <= types


def test_timing_consistency_measured(tmp_path):
    result, _ = _analyze("timing_jitter", tmp_path)
    var = _metric(result, "cycle_to_cycle_timing_variability")
    assert var["classification"] == "measured"
    assert var["value"] is not None
    assert float(var["value"]) > 0
    late = _metric(result, "late_clip_stroke_rate_change")
    assert late["value"] is not None


def test_predicted_versus_labeled_boundary_report(tmp_path):
    """Acceptance helper: emit predicted vs labeled comparison for the clean clip."""
    result, labels = _analyze("clean_side_view", tmp_path)
    errs = _entry_errors(result.entry_frames, labels["entry_frames"])
    stroke_count_error = abs(int(result.summary["stroke_count"] or 0) - int(labels["n_cycles"]))
    # Timing error: mean |pred-exp| duration using matched entries
    pred = result.entry_frames
    exp = labels["entry_frames"]
    matched_pred = []
    for e in exp:
        matched_pred.append(min(pred, key=lambda p: abs(p - e)))
    # Convert frame deltas to ms using pose timestamps
    poses, _ = _load("clean_side_view")
    ts = {p["frame_number"]: p["timestamp_ms"] for p in poses}
    timing_errors_ms = [abs(ts[a] - ts[b]) for a, b in zip(matched_pred, exp)]
    report = {
        "expected_entry_frames": exp,
        "predicted_entry_frames": pred,
        "per_entry_frame_error": errs,
        "max_frame_error": max(errs),
        "stroke_count_error": stroke_count_error,
        "mean_timing_error_ms": sum(timing_errors_ms) / len(timing_errors_ms),
        "max_timing_error_ms": max(timing_errors_ms),
    }
    out = tmp_path / "pred_vs_label.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")
    assert report["stroke_count_error"] == 0
    assert report["max_frame_error"] <= ENTRY_TOLERANCE_FRAMES
    assert report["mean_timing_error_ms"] <= 100.0

"""Milestone 6 underwater / kick / breakout tests against manually labeled fixtures."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.services.underwater import UnderwaterAnalyzer

FIX = Path(__file__).resolve().parents[1] / "fixtures" / "underwater"
KICK_TOLERANCE = 4
BREAKOUT_TOLERANCE = 5


def _load(name: str) -> tuple[list[dict], dict]:
    poses = json.loads((FIX / f"{name}.smoothed_pose.json").read_text())["poses"]
    labels = json.loads((FIX / f"{name}.labels.json").read_text())
    return poses, labels


def _analyze(name: str, tmp_path: Path):
    poses, labels = _load(name)
    analyzer = UnderwaterAnalyzer()
    result = analyzer.analyze(
        poses,
        job_id=f"test-{name}",
        video_id=name,
        output_dir=tmp_path / name,
        view_hint=labels.get("view", "side"),
        surface_stroke_entry_frames=labels.get("surface_stroke_entry_frames"),
        track_observations=labels.get("track_observations"),
        frame_splash_scores={int(k): float(v) for k, v in (labels.get("splash_scores") or {}).items()}
        or None,
        pool_distance_calibrated=False,
    )
    return result, labels


def _metric(result, name: str) -> dict:
    for m in result.metrics:
        if m["name"] == name:
            return m
    raise KeyError(name)


def _event_prf(predicted: list[int], expected: list[int], tol: int) -> tuple[float, float]:
    if not expected and not predicted:
        return 1.0, 1.0
    tp = sum(1 for e in expected if any(abs(p - e) <= tol for p in predicted))
    precision = tp / len(predicted) if predicted else 0.0
    recall = tp / len(expected) if expected else 0.0
    return precision, recall


def test_clean_underwater_breakout_kick_and_breakout(tmp_path):
    result, labels = _analyze("clean_underwater_breakout", tmp_path)
    assert abs(int(result.summary["kick_count"]) - labels["kick_count"]) == 0
    assert abs(result.breakout_frame - labels["breakout_frame"]) <= BREAKOUT_TOLERANCE
    assert abs(result.first_surface_stroke_frame - labels["first_surface_stroke_frame"]) <= BREAKOUT_TOLERANCE
    assert result.phase is not None
    assert abs(result.phase["start_frame"] - labels["underwater_start_frame"]) <= 8
    p, r = _event_prf(result.kick_frames, labels["kick_frames"], KICK_TOLERANCE)
    assert p >= 0.8 and r >= 0.8
    assert Path(result.artifact_paths["underwater_events_json"]).is_file()
    assert Path(result.artifact_paths["chart_ankle_trajectory"]).is_file()
    assert Path(result.artifact_paths["chart_kick_peaks"]).is_file()


def test_already_underwater_when_clip_begins(tmp_path):
    result, labels = _analyze("already_underwater_start", tmp_path)
    assert "already_underwater_at_clip_start" in result.quality_flags
    assert result.summary["kick_count"] == labels["kick_count"]
    assert abs(result.breakout_frame - labels["breakout_frame"]) <= BREAKOUT_TOLERANCE


def test_clip_begins_after_breakout(tmp_path):
    result, labels = _analyze("after_breakout_only", tmp_path)
    assert result.phase is None
    assert result.summary["kick_count"] in (None, 0)
    assert "no_valid_underwater_phase" in result.quality_flags or "clip_begins_after_breakout" in result.quality_flags


def test_no_visible_water_entry(tmp_path):
    result, labels = _analyze("no_visible_water_entry", tmp_path)
    assert result.phase is not None
    assert result.summary["kick_count"] == labels["kick_count"]


def test_feet_obscured(tmp_path):
    result, labels = _analyze("feet_obscured", tmp_path)
    assert "feet_obscured" in result.quality_flags or "oscillation_from_hip" in "".join(result.quality_flags)
    assert abs(int(result.summary["kick_count"]) - labels["kick_count"]) <= 1
    assert abs(result.breakout_frame - labels["breakout_frame"]) <= BREAKOUT_TOLERANCE


def test_bubbles_and_splash(tmp_path):
    result, labels = _analyze("bubbles_splash", tmp_path)
    assert result.summary["kick_count"] == labels["kick_count"]
    assert abs(result.breakout_frame - labels["breakout_frame"]) <= BREAKOUT_TOLERANCE


def test_underwater_camera_view(tmp_path):
    result, labels = _analyze("underwater_camera", tmp_path)
    assert "underwater_camera_view" in result.quality_flags
    assert result.phase is not None
    assert result.summary["kick_count"] == labels["kick_count"]


def test_deck_view(tmp_path):
    result, labels = _analyze("deck_view", tmp_path)
    assert result.phase is not None
    assert abs(int(result.summary["kick_count"]) - labels["kick_count"]) <= 1


def test_short_clip(tmp_path):
    result, _ = _analyze("short_clip", tmp_path)
    assert result.phase is None or "short_clip" in result.quality_flags or "underwater_phase_too_short" in result.quality_flags
    kick = _metric(result, "estimated_underwater_kick_count")
    # short clip → unavailable or zero
    assert kick["value"] in (None, 0)


def test_no_valid_underwater_phase(tmp_path):
    result, _ = _analyze("no_underwater_phase", tmp_path)
    assert result.phase is None
    dur = _metric(result, "underwater_duration")
    assert dur["value"] is None
    assert dur["unavailable_reason"]


def test_camera_movement(tmp_path):
    result, labels = _analyze("camera_movement", tmp_path)
    assert result.summary["kick_count"] == labels["kick_count"]
    assert abs(result.breakout_frame - labels["breakout_frame"]) <= BREAKOUT_TOLERANCE


def test_breakout_distance_unavailable_without_calibration(tmp_path):
    result, _ = _analyze("clean_underwater_breakout", tmp_path)
    d = _metric(result, "breakout_distance")
    assert d["value"] is None
    assert "calibration" in (d["unavailable_reason"] or "")


def test_event_schema_fields(tmp_path):
    result, _ = _analyze("clean_underwater_breakout", tmp_path)
    required = {
        "event_type",
        "timestamp_ms",
        "frame_number",
        "confidence",
        "method",
        "supporting_landmarks",
        "quality_flags",
    }
    for e in result.events:
        assert required.issubset(e.keys())
    types = {e["event_type"] for e in result.events}
    assert {"underwater_start", "dolphin_kick", "breakout", "underwater_end"} <= types


def test_metrics_include_supporting_frames(tmp_path):
    result, _ = _analyze("clean_underwater_breakout", tmp_path)
    rate = _metric(result, "kick_frequency")
    assert rate["value"] is not None
    assert rate["supporting_frame_numbers"]
    assert rate["supporting_timestamps_ms"]
    conf = _metric(result, "breakout_confidence")
    assert conf["value"] is not None and conf["value"] > 0


def test_predicted_versus_labeled_errors(tmp_path):
    result, labels = _analyze("clean_underwater_breakout", tmp_path)
    kick_count_error = abs(int(result.summary["kick_count"]) - int(labels["kick_count"]))
    breakout_frame_error = abs(int(result.breakout_frame) - int(labels["breakout_frame"]))
    poses, _ = _load("clean_underwater_breakout")
    ts = {p["frame_number"]: p["timestamp_ms"] for p in poses}
    breakout_timestamp_error_ms = abs(
        ts[result.breakout_frame] - labels["breakout_timestamp_ms"]
    )
    precision, recall = _event_prf(result.kick_frames, labels["kick_frames"], KICK_TOLERANCE)
    report = {
        "kick_count_expected": labels["kick_count"],
        "kick_count_predicted": result.summary["kick_count"],
        "kick_count_error": kick_count_error,
        "breakout_frame_expected": labels["breakout_frame"],
        "breakout_frame_predicted": result.breakout_frame,
        "breakout_frame_error": breakout_frame_error,
        "breakout_timestamp_error_ms": breakout_timestamp_error_ms,
        "kick_event_precision": precision,
        "kick_event_recall": recall,
        "predicted_kick_frames": result.kick_frames,
        "labeled_kick_frames": labels["kick_frames"],
    }
    (tmp_path / "uw_pred_vs_label.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    assert report["kick_count_error"] == 0
    assert report["breakout_frame_error"] <= BREAKOUT_TOLERANCE
    assert report["breakout_timestamp_error_ms"] <= 200.0
    assert report["kick_event_precision"] >= 0.8
    assert report["kick_event_recall"] >= 0.8

"""Milestone 7 turn / finish tests against manually labeled fixtures."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.services.turn_finish import FinishAnalyzer, TurnAnalyzer, calibrate_wall

FIX = Path(__file__).resolve().parents[1] / "fixtures" / "turn_finish"
FRAME_TOL = 4


def _load(name: str) -> tuple[list[dict], dict]:
    poses = json.loads((FIX / f"{name}.smoothed_pose.json").read_text())["poses"]
    labels = json.loads((FIX / f"{name}.labels.json").read_text())
    return poses, labels


def _event(result, name: str) -> dict:
    for e in result.events:
        if e["event_type"] == name:
            return e
    raise KeyError(name)


def _metric(result, name: str) -> dict:
    for m in result.metrics:
        if m["name"] == name:
            return m
    raise KeyError(name)


def _analyze_turn(name: str, tmp_path: Path, **kwargs):
    poses, labels = _load(name)
    params = {
        "view_hint": labels.get("view", "side"),
        "stroke_hint": labels.get("stroke", "butterfly"),
        "turn_type_hint": labels.get("turn_type"),
        "manual_wall_line": labels.get("manual_wall_line"),
        "surface_stroke_entry_frames": labels.get("surface_stroke_entry_frames"),
        "underwater_kick_frames": labels.get("underwater_kick_frames"),
        "breakout_frame": labels.get("breakout_frame"),
        "frame_width": labels.get("frame_width"),
    }
    params.update(kwargs)
    result = TurnAnalyzer().analyze(
        poses,
        job_id=f"test-{name}",
        video_id=name,
        output_dir=tmp_path / name,
        **params,
    )
    return result, labels


def _analyze_finish(name: str, tmp_path: Path, **kwargs):
    poses, labels = _load(name)
    params = {
        "view_hint": labels.get("view", "side"),
        "stroke_hint": labels.get("stroke", "butterfly"),
        "manual_wall_line": labels.get("manual_wall_line"),
        "surface_stroke_entry_frames": labels.get("surface_stroke_entry_frames"),
        "frame_width": labels.get("frame_width"),
        "clip_ends_before_contact": bool(labels.get("clip_ends_before_contact")),
    }
    params.update(kwargs)
    result = FinishAnalyzer().analyze(
        poses,
        job_id=f"test-{name}",
        video_id=name,
        output_dir=tmp_path / name,
        **params,
    )
    return result, labels


def test_wall_calibration_methods_preserve_confidence():
    poses, labels = _load("turn_flip_clean")
    manual = calibrate_wall(
        smoothed_poses=poses,
        frame_width=labels["frame_width"],
        manual_wall_line=labels["manual_wall_line"],
    )
    assert manual.method == "manual_wall_line"
    assert manual.confidence >= 0.9
    assert manual.wall_in_frame is True

    geom = calibrate_wall(
        smoothed_poses=poses,
        frame_width=labels["frame_width"],
        pool_geometry={"wall_x": 600.0, "meters_per_pixel": 0.02, "confidence": 0.82},
    )
    assert geom.method == "pool_geometry"
    assert geom.confidence == pytest.approx(0.82)
    assert geom.meters_per_pixel == pytest.approx(0.02)

    block = calibrate_wall(
        smoothed_poses=poses,
        frame_width=labels["frame_width"],
        starting_block_x=610.0,
    )
    assert block.method == "starting_block"
    assert block.confidence > 0

    lane = calibrate_wall(
        smoothed_poses=poses,
        frame_width=labels["frame_width"],
        lane_line_termination_x=615.0,
    )
    assert lane.method == "lane_line_termination"

    auto = calibrate_wall(smoothed_poses=poses, frame_width=labels["frame_width"], auto_detect=True)
    assert auto.method in {"trajectory_asymptote", "auto_edge", "unavailable"}


def test_flip_turn_labeled_events(tmp_path):
    result, labels = _analyze_turn("turn_flip_clean", tmp_path)
    assert result.view_supported is True
    assert abs(_event(result, "wall_contact")["frame_number"] - labels["wall_contact_frame"]) <= FRAME_TOL
    assert abs(_event(result, "push_off")["frame_number"] - labels["push_off_frame"]) <= FRAME_TOL
    assert abs(_event(result, "breakout")["frame_number"] - labels["breakout_frame"]) <= FRAME_TOL
    assert (
        abs(_event(result, "final_stroke_before_wall")["frame_number"] - labels["final_stroke_before_wall_frame"])
        <= FRAME_TOL
    )
    assert "flip_turn" in _event(result, "wall_contact")["quality_flags"]
    assert Path(result.artifact_paths["turn_timeline"]).is_file()
    assert Path(result.artifact_paths["wall_calibration_frame"]).is_file()
    assert Path(result.artifact_paths["turn_events_json"]).is_file()
    assert Path(result.artifact_paths["turn_confidence_report"]).is_file()


def test_open_turn_foot_placement_unavailable(tmp_path):
    result, _ = _analyze_turn("turn_open", tmp_path)
    foot = _event(result, "foot_placement")
    assert foot["frame_number"] is None
    assert foot["unavailable_reason"]
    assert "open_turn" in _event(result, "wall_contact")["quality_flags"]


def test_wall_outside_view_does_not_claim_contact(tmp_path):
    result, labels = _analyze_turn("turn_wall_outside", tmp_path)
    assert result.calibration["wall_in_frame"] is False
    contact = _event(result, "wall_contact")
    assert contact["frame_number"] is None
    assert "wall_outside" in (contact["unavailable_reason"] or "")
    assert labels["wall_contact_frame"] is None
    # Exact contact metrics must be unavailable
    assert _metric(result, "time_final_stroke_to_wall_contact")["value"] is None
    assert _metric(result, "time_lost")["value"] is None
    assert "comparison" in (_metric(result, "time_lost")["unavailable_reason"] or "")


def test_finish_labeled_contact_and_final_stroke(tmp_path):
    result, labels = _analyze_finish("finish_clean", tmp_path)
    assert abs(_event(result, "wall_contact")["frame_number"] - labels["finish_contact_frame"]) <= FRAME_TOL
    assert (
        abs(_event(result, "final_hand_entry")["frame_number"] - labels["final_stroke_boundary_frame"])
        <= FRAME_TOL
    )
    assert (
        abs(
            _event(result, "final_complete_stroke_cycle")["frame_number"]
            - labels["final_complete_stroke_cycle_frame"]
        )
        <= FRAME_TOL
    )
    assert "two_hand_touch_expected" in _event(result, "wall_contact")["quality_flags"]
    assert _metric(result, "finish_timing_confidence")["value"] is not None
    assert Path(result.artifact_paths["finish_timeline"]).is_file()


def test_finish_contact_not_visible(tmp_path):
    result, labels = _analyze_finish("finish_contact_not_visible", tmp_path)
    contact = _event(result, "wall_contact")
    assert contact["frame_number"] is None
    assert labels["finish_contact_frame"] is None
    assert contact["unavailable_reason"]


def test_finish_clip_ends_before_contact(tmp_path):
    result, labels = _analyze_finish("finish_clip_ends_early", tmp_path)
    contact = _event(result, "wall_contact")
    assert contact["frame_number"] is None
    assert "clip_ending" in (contact["unavailable_reason"] or "")
    assert labels["clip_ends_before_contact"] is True


def test_unsupported_view_returns_unavailable(tmp_path):
    result, _ = _analyze_turn("turn_flip_clean", tmp_path, view_hint="end")
    assert result.view_supported is False
    for e in result.events:
        assert e["frame_number"] is None
        assert e["unavailable_reason"]
    assert _metric(result, "approach_duration")["value"] is None


def test_moving_camera_and_blocked_flags(tmp_path):
    result, _ = _analyze_turn(
        "turn_flip_clean",
        tmp_path,
        moving_camera=True,
        blocked_by_obstacle=True,
    )
    assert "moving_camera" in result.quality_flags
    assert "swimmer_blocked_by_official_or_lane_rope" in result.quality_flags
    assert _event(result, "wall_contact")["frame_number"] is None


def test_event_and_metric_schema_fields(tmp_path):
    result, _ = _analyze_turn("turn_flip_clean", tmp_path)
    event_required = {
        "event_type",
        "timestamp_ms",
        "frame_number",
        "confidence",
        "method",
        "supporting_frames",
        "supporting_timestamps_ms",
        "quality_flags",
        "limitations",
        "value",
        "unit",
    }
    for e in result.events:
        assert event_required.issubset(e.keys())
    metric_required = {
        "name",
        "value",
        "unit",
        "confidence",
        "method",
        "supporting_frame_numbers",
        "supporting_timestamps_ms",
        "quality_flags",
        "limitations",
    }
    for m in result.metrics:
        assert metric_required.issubset(m.keys())


def test_predicted_versus_labeled_report(tmp_path):
    turn, tlabels = _analyze_turn("turn_flip_clean", tmp_path)
    finish, flabels = _analyze_finish("finish_clean", tmp_path / "finish")
    report = {
        "turn": {
            "wall_contact": {
                "predicted": _event(turn, "wall_contact")["frame_number"],
                "labeled": tlabels["wall_contact_frame"],
            },
            "push_off": {
                "predicted": _event(turn, "push_off")["frame_number"],
                "labeled": tlabels["push_off_frame"],
            },
            "breakout": {
                "predicted": _event(turn, "breakout")["frame_number"],
                "labeled": tlabels["breakout_frame"],
            },
            "final_stroke_before_wall": {
                "predicted": _event(turn, "final_stroke_before_wall")["frame_number"],
                "labeled": tlabels["final_stroke_before_wall_frame"],
            },
        },
        "finish": {
            "finish_contact": {
                "predicted": _event(finish, "wall_contact")["frame_number"],
                "labeled": flabels["finish_contact_frame"],
            },
            "final_stroke_boundary": {
                "predicted": _event(finish, "final_hand_entry")["frame_number"],
                "labeled": flabels["final_stroke_boundary_frame"],
            },
        },
    }
    out = tmp_path / "m7_pred_vs_label.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")
    for pair in report["turn"].values():
        assert abs(pair["predicted"] - pair["labeled"]) <= FRAME_TOL
    for pair in report["finish"].values():
        assert abs(pair["predicted"] - pair["labeled"]) <= FRAME_TOL


def test_no_gemini_narrative_imports():
    import app.services.turn_finish as pkg
    import app.services.turn_finish.turn_analyzer as ta
    import app.services.turn_finish.finish_analyzer as fa

    src = "\n".join([Path(m.__file__).read_text(encoding="utf-8") for m in (pkg, ta, fa)])
    assert "gemini" not in src.lower()
    assert "GenerativeModel" not in src

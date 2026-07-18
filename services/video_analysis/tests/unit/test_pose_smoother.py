"""Milestone 4 pose validation / smoothing unit tests."""

from __future__ import annotations

import copy
import json
from pathlib import Path

import cv2
import numpy as np
import pytest

from app.domain.landmarks import COCO_WHOLEBODY_KEYPOINT_NAMES
from app.services.pose_overlay import map_overlay_point_from_crop, render_skeleton_overlay
from app.services.pose_smoother import SmoothingParams, smooth_pose_sequence
from app.services.pose_validation import run_pose_validation


WRIST = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_wrist")
ANKLE = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_ankle")
NOSE = COCO_WHOLEBODY_KEYPOINT_NAMES.index("nose")
SHOULDER = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_shoulder")
HIP = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_hip")
ELBOW = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_elbow")
KNEE = COCO_WHOLEBODY_KEYPOINT_NAMES.index("left_knee")
CORE = [NOSE, SHOULDER, ELBOW, WRIST, HIP, KNEE, ANKLE]


def _empty_kps() -> list[dict]:
    return [
        {
            "name": name,
            "x": None,
            "y": None,
            "z": None,
            "confidence": 0.0,
            "x_crop": None,
            "y_crop": None,
        }
        for name in COCO_WHOLEBODY_KEYPOINT_NAMES
    ]


def _pose(
    frame: int,
    *,
    pts: dict[int, tuple[float, float, float]] | None = None,
    timestamp_ms: float | None = None,
    unusable_reason: str | None = None,
    quality_flags: list[str] | None = None,
    crop: list[float] | None = None,
) -> dict:
    kps = _empty_kps()
    crop = crop or [10.0, 20.0, 210.0, 420.0]
    for idx, (x, y, c) in (pts or {}).items():
        kps[idx] = {
            "name": COCO_WHOLEBODY_KEYPOINT_NAMES[idx],
            "x": x,
            "y": y,
            "z": None,
            "confidence": c,
            "x_crop": x - crop[0],
            "y_crop": y - crop[1],
        }
    return {
        "video_id": "v1",
        "job_id": "j1",
        "frame_number": frame,
        "timestamp_ms": timestamp_ms if timestamp_ms is not None else frame * (1000.0 / 30.0),
        "swimmer_track_id": "track-1",
        "crop_coordinates": crop,
        "keypoints": kps,
        "overall_pose_confidence": float(np.mean([k["confidence"] for k in kps])),
        "model_name": "test",
        "model_version": "0",
        "inference_resolution": [192, 256],
        "processing_duration_ms": 1.0,
        "usable": True,
        "unusable_reason": unusable_reason,
        "quality_flags": quality_flags or [],
    }


def _core_pts(x: float, y: float, conf: float = 0.9) -> dict[int, tuple[float, float, float]]:
    return {
        NOSE: (x, y, conf),
        SHOULDER: (x + 10, y + 40, conf),
        ELBOW: (x + 20, y + 80, conf),
        WRIST: (x + 30, y + 120, conf),
        HIP: (x + 5, y + 140, conf),
        KNEE: (x + 8, y + 200, conf),
        ANKLE: (x + 10, y + 260, conf),
    }


def test_isolated_missing_frame_interpolated():
    poses = [
        _pose(0, pts=_core_pts(100, 100)),
        _pose(1, pts={}),  # missing
        _pose(2, pts=_core_pts(104, 104)),
    ]
    original = copy.deepcopy(poses)
    result = smooth_pose_sequence(poses, params=SmoothingParams(max_interpolation_gap_frames=3))
    assert result.raw_poses == original
    assert poses == original  # input unchanged
    wrist = result.smoothed_poses[1]["keypoints"][WRIST]
    assert wrist["quality_flag"] == "interpolated"
    assert wrist["x"] is not None
    # left_wrist is offset +30 from the core anchor x in the fixture helper
    assert 130 < wrist["x"] < 135


def test_short_missing_sequence_interpolated():
    poses = [
        _pose(0, pts=_core_pts(100, 100)),
        _pose(1, pts={}),
        _pose(2, pts={}),
        _pose(3, pts=_core_pts(109, 109)),
    ]
    result = smooth_pose_sequence(poses, params=SmoothingParams(max_interpolation_gap_frames=3))
    for i in (1, 2):
        assert result.smoothed_poses[i]["keypoints"][WRIST]["quality_flag"] == "interpolated"
        assert result.smoothed_poses[i]["keypoints"][WRIST]["x"] is not None


def test_long_occlusion_remains_unavailable():
    poses = [_pose(0, pts=_core_pts(100, 100))]
    for i in range(1, 10):
        poses.append(
            _pose(
                i,
                pts={},
                unusable_reason="severe_occlusion",
                quality_flags=["severe_occlusion"],
            )
        )
    poses.append(_pose(10, pts=_core_pts(120, 120)))
    result = smooth_pose_sequence(
        poses,
        params=SmoothingParams(max_interpolation_gap_frames=3, long_occlusion_gap_frames=8),
    )
    mid = result.smoothed_poses[5]["keypoints"][WRIST]
    assert mid["x"] is None
    assert mid["quality_flag"] in {"occluded", "unavailable"}
    assert result.coverage.longest_missing_interval_frames >= 8


def test_sudden_impossible_joint_movement_outlier():
    poses = [
        _pose(0, pts=_core_pts(100, 100)),
        _pose(1, pts=_core_pts(100, 100)),
        _pose(2, pts=_core_pts(500, 500)),  # teleport
        _pose(3, pts=_core_pts(102, 102)),
    ]
    result = smooth_pose_sequence(
        poses,
        params=SmoothingParams(continuity_max_jump_px=80.0, max_joint_velocity_px_s=1000.0),
    )
    flag = result.smoothed_poses[2]["keypoints"][WRIST]["quality_flag"]
    # Outlier removed, then possibly short-gap interpolated between 1 and 3
    assert flag in {"outlier_removed", "interpolated", "unavailable"}
    if flag == "outlier_removed":
        assert result.smoothed_poses[2]["keypoints"][WRIST]["x"] is None
    else:
        # If refilled, must not keep the teleport coordinate
        assert result.smoothed_poses[2]["keypoints"][WRIST]["x"] is not None
        assert result.smoothed_poses[2]["keypoints"][WRIST]["x"] < 200


def test_noisy_wrist_coordinates_smoothed():
    poses = []
    for i in range(9):
        noise = 6.0 if i % 2 else -6.0
        pts = _core_pts(100 + i, 100 + i)
        wx, wy, wc = pts[WRIST]
        pts[WRIST] = (wx + noise, wy + noise, wc)
        poses.append(_pose(i, pts=pts))
    # Keep velocity/accel gates loose so this case exercises Savitzky–Golay, not outlier removal.
    result = smooth_pose_sequence(
        poses,
        params=SmoothingParams(
            savgol_window=5,
            savgol_polyorder=2,
            max_joint_velocity_px_s=20000.0,
            max_joint_acceleration_px_s2=500000.0,
            continuity_max_jump_px=80.0,
        ),
    )
    xs = [p["keypoints"][WRIST]["x"] for p in result.smoothed_poses]
    assert all(x is not None for x in xs)
    raw_xs = [100 + i + 30 + (6 if i % 2 else -6) for i in range(9)]
    assert float(np.std(xs)) < float(np.std(raw_xs))


def test_low_confidence_ankle_not_treated_as_valid_motion():
    poses = []
    for i in range(5):
        pts = _core_pts(100 + i, 100 + i, conf=0.9)
        # Low-confidence ankle "noise" that would invent motion if trusted
        pts[ANKLE] = (100 + i * 50, 260 + i * 50, 0.05)
        poses.append(_pose(i, pts=pts))
    result = smooth_pose_sequence(poses, params=SmoothingParams(min_keypoint_confidence=0.30))
    for p in result.smoothed_poses:
        ankle = p["keypoints"][ANKLE]
        assert ankle["quality_flag"] == "low_confidence"
        assert ankle["x"] is None


def test_variable_frame_rate_velocity_check():
    # Large dt between frames → same pixel jump is slower in px/s and may pass;
    # tiny dt → same jump fails velocity check.
    pts_a = _core_pts(100, 100)
    pts_b = _core_pts(160, 100)  # 60px jump on wrist-ish core
    poses_fast = [
        _pose(0, pts=pts_a, timestamp_ms=0.0),
        _pose(1, pts=pts_b, timestamp_ms=10.0),  # 0.01s → 6000 px/s
    ]
    poses_slow = [
        _pose(0, pts=pts_a, timestamp_ms=0.0),
        _pose(1, pts=pts_b, timestamp_ms=200.0),  # 0.2s → 300 px/s
    ]
    params = SmoothingParams(
        max_joint_velocity_px_s=2000.0,
        continuity_max_jump_px=200.0,
        max_interpolation_gap_frames=0,  # do not refill after outlier
    )
    fast = smooth_pose_sequence(poses_fast, params=params)
    slow = smooth_pose_sequence(poses_slow, params=params)
    assert fast.smoothed_poses[1]["keypoints"][WRIST]["quality_flag"] == "outlier_removed"
    assert slow.smoothed_poses[1]["keypoints"][WRIST]["quality_flag"] == "valid"


def test_overlay_coordinate_alignment_no_crop_distortion():
    crop = [40.0, 60.0, 240.0, 460.0]
    x_full, y_full = map_overlay_point_from_crop(25.0, 35.0, crop)
    assert x_full == pytest.approx(65.0)
    assert y_full == pytest.approx(95.0)


def test_raw_data_remains_unchanged_through_validation(tmp_path, settings):
    poses = [_pose(i, pts=_core_pts(100 + i, 100 + i)) for i in range(5)]
    original = copy.deepcopy(poses)
    # tiny synthetic video
    video = tmp_path / "clip.mp4"
    w, h, fps = 160, 120, 10
    writer = cv2.VideoWriter(str(video), cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
    for i in range(5):
        frame = np.zeros((h, w, 3), dtype=np.uint8)
        writer.write(frame)
    writer.release()

    settings.pose_smoothing_enabled = True
    out = tmp_path / "out"
    # Write raw first (as M3 does)
    raw_path = out / "raw_pose.json"
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw_path.write_text(json.dumps({"dataset": "raw", "poses": poses}, indent=2), encoding="utf-8")

    result = run_pose_validation(
        settings=settings,
        job_id="j1",
        video_id="v1",
        raw_poses=poses,
        output_root=out,
        video_path=video,
    )
    assert poses == original
    disk = json.loads(raw_path.read_text(encoding="utf-8"))
    assert disk["poses"] == original
    assert Path(result.artifact_paths["smoothed_pose_json"]).is_file()
    assert Path(result.artifact_paths["skeleton_overlay_video"]).is_file()
    assert Path(result.artifact_paths["pose_quality_report"]).is_file()
    assert Path(result.artifact_paths["frame_confidence_json"]).is_file()
    assert result.coverage["pose_coverage_percentage"] > 0
    assert result.coverage["usable_frame_percentage"] > 0


def test_overlay_renders_with_hud(tmp_path):
    video = tmp_path / "v.mp4"
    w, h, fps = 128, 96, 5
    writer = cv2.VideoWriter(str(video), cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
    for _ in range(3):
        writer.write(np.zeros((h, w, 3), dtype=np.uint8))
    writer.release()

    poses = []
    for i in range(3):
        p = _pose(i, pts=_core_pts(40 + i, 30 + i), crop=[0, 0, w, h])
        for kp in p["keypoints"]:
            if kp["x"] is not None:
                kp["quality_flag"] = "valid"
        poses.append(p)

    out = tmp_path / "overlay.mp4"
    render_skeleton_overlay(video, poses, out, job_id="job-demo")
    assert out.is_file()
    assert out.stat().st_size > 0
    cap = cv2.VideoCapture(str(out))
    assert int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) == w
    assert int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) == h
    cap.release()


def test_no_swimming_performance_metrics_exported():
    """Guardrail: M4 artifacts must not include stroke/underwater/turn metrics."""
    poses = [_pose(i, pts=_core_pts(100 + i, 100)) for i in range(4)]
    result = smooth_pose_sequence(poses)
    blob = json.dumps(result.smoothed_poses) + json.dumps(result.coverage.to_dict())
    forbidden = ["stroke_rate", "dps", "underwater", "turn_time", "gemini"]
    for word in forbidden:
        assert word not in blob.lower()

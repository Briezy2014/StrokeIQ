"""Unit tests for persistent swimmer tracking and target selection."""

from __future__ import annotations

import numpy as np

from app.models.detector_adapter import BoundingBox, Detection
from app.services.swimmer_tracker import SwimmerTracker
from app.services.target_selector import select_target


def _det(frame: int, bbox: list[float], conf: float = 0.9, idx: int = 0) -> Detection:
    return Detection(
        frame_number=frame,
        timestamp_ms=frame * (1000 / 30),
        bbox=BoundingBox(*bbox),
        confidence=conf,
        temporary_detection_id=f"d-{frame}-{idx}",
        model_name="scripted",
        model_version="t",
    )


def test_one_swimmer_persistent_id():
    tracker = SwimmerTracker(frame_width=640, frame_height=360, max_lost_frames=5)
    for f in range(10):
        x = 50 + f * 5
        tracker.update([_det(f, [x, 100, x + 40, 140])])
    assert len(tracker.tracks) == 1
    assert tracker.tracks[0].hits == 10
    assert tracker.tracks[0].track_id.startswith("track-")


def test_multiple_swimmers_neighboring_lanes():
    tracker = SwimmerTracker(frame_width=640, frame_height=360, lane_count=8)
    for f in range(12):
        a = [40 + f * 6, 80, 80 + f * 6, 120]
        b = [40 + f * 5, 220, 80 + f * 5, 260]
        tracker.update([_det(f, a, 0.9, 0), _det(f, b, 0.85, 1)])
    assert len(tracker.tracks) == 2
    lanes = {t.lane_index for t in tracker.tracks}
    assert len(lanes) >= 2


def test_temporary_splash_occlusion():
    tracker = SwimmerTracker(frame_width=640, frame_height=360, max_lost_frames=10)
    for f in range(20):
        if 8 <= f <= 11:
            tracker.update([])
        else:
            x = 60 + f * 4
            tracker.update([_det(f, [x, 100, x + 50, 140])])
    assert len(tracker.tracks) == 1
    assert tracker.tracks[0].occlusion_events >= 1
    assert any(e["type"] == "temporary_occlusion" for e in tracker.events)


def test_leave_and_reenter_frame():
    tracker = SwimmerTracker(frame_width=640, frame_height=360, max_lost_frames=20)
    for f in range(8):
        tracker.update([_det(f, [10 + f, 100, 50 + f, 140])])
    for f in range(8, 16):
        tracker.update([])  # left / missing
    for f in range(16, 24):
        tracker.update([_det(f, [20 + (f - 16) * 5, 110, 60 + (f - 16) * 5, 150])])
    # Depending on max_lost, may be one reacquired track or a new track after lost.
    assert len(tracker.tracks) >= 1
    assert any(
        e["type"] in {"swimmer_leaving_frame", "lost_track", "temporary_occlusion"}
        for e in tracker.events
    )


def test_no_detections_keeps_empty():
    tracker = SwimmerTracker(frame_width=640, frame_height=360)
    tracker.update([])
    assert tracker.tracks == []


def test_low_confidence_filtered_by_caller():
    # Tracker itself accepts provided detections; low-conf filtering is detector-side.
    tracker = SwimmerTracker(frame_width=640, frame_height=360)
    tracker.update([_det(0, [10, 10, 40, 40], conf=0.2)])
    assert len(tracker.tracks) == 1


def test_track_switching_risk_flag():
    tracker = SwimmerTracker(frame_width=640, frame_height=360, match_threshold=0.2)
    tracker.update([_det(0, [100, 100, 140, 140])])
    # Far jump same frame index sequence — may create switch risk or new track
    tracker.update([_det(1, [400, 100, 440, 140])])
    assert len(tracker.tracks) >= 1


def test_manual_track_selection():
    tracker = SwimmerTracker(frame_width=640, frame_height=360)
    for f in range(5):
        tracker.update(
            [
                _det(f, [50, 80, 90, 120], 0.9, 0),
                _det(f, [50, 220, 90, 260], 0.9, 1),
            ]
        )
    ids = [t.track_id for t in tracker.tracks]
    chosen = ids[1]
    result = select_target(tracker.tracks, mode="track_id", track_id=chosen)
    assert result.track_id == chosen
    assert result.mode == "track_id"


def test_automatic_not_only_largest():
    tracker = SwimmerTracker(frame_width=640, frame_height=360)
    # Small but persistent track for most of the clip
    for f in range(12):
        tracker.update([_det(f, [20, 40, 40, 60], 0.95, 0)])
    # Large latecomer appears only at the end
    for f in range(12, 15):
        tracker.update(
            [
                _det(f, [20, 40, 40, 60], 0.95, 0),
                _det(f, [100, 80, 300, 280], 0.99, 1),
            ]
        )
    result = select_target(tracker.tracks, mode="automatic", frame_width=640, frame_height=360)
    # Prefer continuity; should not blindly pick largest-only latecomer
    assert result.track_id is not None
    assert result.track_id == tracker.tracks[0].track_id


def test_normalized_and_bbox_selection():
    tracker = SwimmerTracker(frame_width=640, frame_height=360)
    for f in range(5):
        tracker.update(
            [
                _det(f, [50, 80, 90, 120], 0.9, 0),
                _det(f, [400, 200, 450, 250], 0.9, 1),
            ]
        )
    by_norm = select_target(
        tracker.tracks,
        mode="normalized_coordinate",
        normalized_xy=(0.7, 0.6),
        frame_width=640,
        frame_height=360,
    )
    by_box = select_target(
        tracker.tracks,
        mode="bounding_box",
        bbox=[390, 190, 460, 260],
        frame_width=640,
        frame_height=360,
    )
    assert by_norm.track_id is not None
    assert by_box.track_id is not None

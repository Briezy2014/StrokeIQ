"""Integration tests for Milestone 2 detection + tracking."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.api.schemas.responses import JobStatus
from app.domain.jobs import AnalysisJob, new_job_id
from app.models.scripted_detector import ScriptedDetectorAdapter
from app.services.job_pipeline import run_analysis_pipeline
from app.services.result_store import ResultStore
from app.services.swimmer_detector import DetectionError, run_detection_and_tracking

FIX = Path(__file__).resolve().parents[1] / "fixtures"
MODEL = Path(__file__).resolve().parents[2] / "models" / "rtmdet-n-person.onnx"


def _load_script(name: str) -> dict[int, list[tuple[list[float], float]]]:
    raw = json.loads((FIX / name).read_text())
    out: dict[int, list[tuple[list[float], float]]] = {}
    for k, items in raw.items():
        out[int(k)] = [(list(map(float, box)), float(conf)) for box, conf in items]
    return out


def test_scripted_multi_swimmer_pipeline(settings):
    settings.frame_processing_interval = 1
    settings.max_target_lost_frames = 80
    video = FIX / "multi_swimmer_synth.mp4"
    script = _load_script("multi_swimmer_script.json")
    detector = ScriptedDetectorAdapter(script)
    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="multi-1",
        engine_version=settings.engine_version,
        request_payload={
            "options": {
                "target_selection_mode": "automatic",
                "generate_overlay": True,
            }
        },
        local_path=str(video),
    )
    store.save(job)
    finished = run_analysis_pipeline(
        job, settings=settings, store=store, detector=detector
    )
    assert finished.status in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
    }
    assert finished.tracking is not None
    assert finished.tracking["detection_count"] > 0
    assert finished.tracking["track_count"] >= 2
    assert finished.tracking["target"]["track_id"]
    arts = finished.tracking["artifact_paths"]
    assert Path(arts["detections_json"]).is_file()
    assert Path(arts["tracks_json"]).is_file()
    assert Path(arts["tracking_quality_summary"]).is_file()
    assert arts["annotated_tracking_video"]
    assert Path(arts["annotated_tracking_video"]).is_file()
    assert finished.model_versions.get("detector")
    # No coaching report / pose
    assert finished.tracking.get("report") is None


def test_manual_track_id_selection(settings):
    settings.max_target_lost_frames = 80
    video = FIX / "multi_swimmer_synth.mp4"
    script = _load_script("multi_swimmer_script.json")
    detector = ScriptedDetectorAdapter(script)
    # Warm-up run to discover IDs
    art = settings.artifact_root / "warm"
    art.mkdir(parents=True, exist_ok=True)
    warm = run_detection_and_tracking(
        settings=settings,
        job_id="warm",
        video_id="warm",
        video_path=video,
        artifact_root=art,
        options={"target_selection_mode": "automatic"},
        detector=detector,
    )
    track_id = warm.tracks[1]["track_id"] if len(warm.tracks) > 1 else warm.tracks[0]["track_id"]

    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="manual-1",
        engine_version=settings.engine_version,
        request_payload={
            "options": {
                "target_selection_mode": "track_id",
                "target_track_id": track_id,
            }
        },
        local_path=str(video),
    )
    finished = run_analysis_pipeline(
        job, settings=settings, store=store, detector=detector
    )
    assert finished.tracking["target"]["track_id"] == track_id
    assert finished.tracking["target"]["mode"] == "track_id"


def test_reenter_scripted(settings):
    settings.max_lost_frames = 30
    settings.max_target_lost_frames = 80
    video = FIX / "reenter_synth.mp4"
    detector = ScriptedDetectorAdapter(_load_script("reenter_script.json"))
    art = settings.artifact_root / "reenter"
    result = run_detection_and_tracking(
        settings=settings,
        job_id="reenter",
        video_id="reenter",
        video_path=video,
        artifact_root=art,
        options={"target_selection_mode": "automatic"},
        detector=detector,
    )
    assert result.tracks
    assert Path(result.artifact_paths["tracks_json"]).is_file()


def test_detector_no_results_fails(settings, valid_video):
    detector = ScriptedDetectorAdapter(script={})
    art = settings.artifact_root / "empty"
    with pytest.raises(DetectionError) as exc:
        run_detection_and_tracking(
            settings=settings,
            job_id="empty",
            video_id="empty",
            video_path=valid_video,
            artifact_root=art,
            detector=detector,
        )
    assert exc.value.error_code == "NO_DETECTIONS"


def test_extended_gap_completes_when_coverage_usable(settings, valid_video):
    """Brief mid-clip disappearance must not hard-fail if enough track remains."""
    settings.max_target_lost_frames = 5
    settings.min_usable_target_coverage = 0.20
    # valid_short is 30 frames: track most of the clip, leave a mid gap > 5 frames.
    script = {
        i: [([80.0, 80.0, 220.0, 320.0], 0.9)]
        for i in list(range(0, 12)) + list(range(20, 30))
    }
    detector = ScriptedDetectorAdapter(script)
    art = settings.artifact_root / "gap_ok"
    result = run_detection_and_tracking(
        settings=settings,
        job_id="gap-ok",
        video_id="gap-ok",
        video_path=valid_video,
        artifact_root=art,
        detector=detector,
    )
    assert result.lost_extended is True
    assert result.completed_with_limitations is True
    assert result.tracks
    assert any("hard to see" in note.lower() for note in result.limitations)


def test_brief_track_still_completes_with_limitations(settings, valid_video):
    """Sparse phone-clip tracks should complete, not hard-fail TARGET_LOST."""
    settings.max_target_lost_frames = 3
    settings.min_usable_target_coverage = 0.20
    settings.frame_processing_interval = 1
    # Enough hits to form a usable track, then a long gap.
    script = {i: [([80.0, 80.0, 220.0, 320.0], 0.9)] for i in range(0, 5)}
    detector = ScriptedDetectorAdapter(script)
    art = settings.artifact_root / "gap-soft"
    result = run_detection_and_tracking(
        settings=settings,
        job_id="gap-soft",
        video_id="gap-soft",
        video_path=valid_video,
        artifact_root=art,
        detector=detector,
    )
    assert result.completed_with_limitations is True
    assert result.tracks
    assert result.lost_extended is True


def test_extended_gap_fails_only_without_usable_track(settings, valid_video):
    """Fail TARGET_LOST_EXTENDED only when no usable track exists."""
    settings.max_target_lost_frames = 1
    settings.min_usable_target_coverage = 0.20
    settings.frame_processing_interval = 1
    # Single detection — not enough hits for a usable track.
    script = {0: [([80.0, 80.0, 220.0, 320.0], 0.9)]}
    detector = ScriptedDetectorAdapter(script)
    art = settings.artifact_root / "gap-bad"
    with pytest.raises(DetectionError) as exc:
        run_detection_and_tracking(
            settings=settings,
            job_id="gap-bad",
            video_id="gap-bad",
            video_path=valid_video,
            artifact_root=art,
            detector=detector,
        )
    assert exc.value.error_code == "TARGET_LOST_EXTENDED"
    assert exc.value.retriable is False


def test_max_analysis_duration_truncates(settings, valid_video):
    """Long clips are truncated so CPU detection stays responsive."""
    settings.frame_processing_interval = 1
    settings.max_analysis_duration_s = 0.2  # ~6 frames at 30fps
    script = {i: [([80.0, 80.0, 220.0, 320.0], 0.9)] for i in range(0, 30)}
    detector = ScriptedDetectorAdapter(script)
    art = settings.artifact_root / "truncate"
    progress_vals: list[float] = []
    result = run_detection_and_tracking(
        settings=settings,
        job_id="truncate",
        video_id="truncate",
        video_path=valid_video,
        artifact_root=art,
        detector=detector,
        on_progress=progress_vals.append,
    )
    assert any("first" in note.lower() for note in result.limitations)
    assert result.quality_summary["processed_frames"] <= 8
    assert progress_vals


def test_low_confidence_all_filtered(settings, valid_video):
    script = {i: [([10, 10, 40, 40], 0.1)] for i in range(30)}
    detector = ScriptedDetectorAdapter(script)
    settings.min_detection_confidence = 0.5
    art = settings.artifact_root / "lowconf"
    with pytest.raises(DetectionError) as exc:
        run_detection_and_tracking(
            settings=settings,
            job_id="low",
            video_id="low",
            video_path=valid_video,
            artifact_root=art,
            detector=detector,
        )
    assert exc.value.error_code == "NO_DETECTIONS"


@pytest.mark.skipif(not MODEL.is_file(), reason="RTMDet model missing")
@pytest.mark.skipif(not (FIX / "person_clip.mp4").is_file(), reason="person clip missing")
def test_rtmdet_person_clip_real_detector(settings):
    settings.min_detection_confidence = 0.3
    settings.frame_processing_interval = 2
    settings.max_target_lost_frames = 120
    settings.detector_model_path = MODEL
    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="person-rtmdet",
        engine_version=settings.engine_version,
        request_payload={
            "options": {
                "target_selection_mode": "automatic",
                "generate_overlay": True,
            }
        },
        local_path=str(FIX / "person_clip.mp4"),
    )
    finished = run_analysis_pipeline(job, settings=settings, store=store)
    assert finished.status in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    }
    if finished.status == JobStatus.failed:
        # Person pan clip may yield sparse detections on some frames; still must not fake success.
        assert finished.error is not None
        assert finished.error.error_code in {
            "NO_DETECTIONS",
            "TARGET_LOST_EXTENDED",
        }
    else:
        assert finished.tracking is not None
        assert finished.tracking["detection_count"] >= 1
        assert Path(finished.tracking["artifact_paths"]["annotated_tracking_video"]).is_file()
        tracks_json = json.loads(
            Path(finished.tracking["artifact_paths"]["tracks_json"]).read_text()
        )
        assert "tracks" in tracks_json
        assert tracks_json["model_name"] == "rtmdet-n-person"


@pytest.mark.skipif(not (FIX / "person_clip_rotated.mp4").is_file(), reason="rotated missing")
def test_rotated_phone_video_scripted_or_real(settings):
    settings.max_target_lost_frames = 120
    # Use scripted single box moving for rotated fixture dimensions
    import cv2

    cap = cv2.VideoCapture(str(FIX / "person_clip_rotated.mp4"))
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    cap.release()
    script = {
        i: [([w * 0.3, h * 0.3, w * 0.6, h * 0.7], 0.88)] for i in range(max(1, n))
    }
    detector = ScriptedDetectorAdapter(script)
    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="rotated",
        engine_version=settings.engine_version,
        request_payload={
            "options": {
                "target_selection_mode": "automatic",
                "generate_overlay": True,
            }
        },
        local_path=str(FIX / "person_clip_rotated.mp4"),
    )
    finished = run_analysis_pipeline(
        job, settings=settings, store=store, detector=detector
    )
    assert finished.status in {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
    }
    assert finished.tracking["artifact_paths"]["annotated_tracking_video"]

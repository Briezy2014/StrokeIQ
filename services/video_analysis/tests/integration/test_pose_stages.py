"""Milestone 3 staged pose acceptance tests (A → B → C, no auto-advance)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.models.rtmdet_adapter import RTMDetOnnxAdapter
from app.models.rtmpose_adapter import clear_model_cache
from app.services.pose_pipeline import PoseStageError, acceptance_path, run_pose_stage

FIX = Path(__file__).resolve().parents[1] / "fixtures"
ROOT = Path(__file__).resolve().parents[2]
CFG = ROOT / "models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py"
CKPT = ROOT / (
    "models/rtmpose/"
    "rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth"
)
DET = ROOT / "models/rtmdet-n-person.onnx"

pytestmark = pytest.mark.skipif(
    not CFG.is_file() or not CKPT.is_file() or not DET.is_file(),
    reason="pose/det models missing",
)


@pytest.fixture()
def pose_settings(settings):
    settings.engine_version = "elote-0.3.0-test"
    settings.pose_enabled = True
    settings.pose_device = "cpu"
    settings.pose_config_path = CFG
    settings.pose_checkpoint_path = CKPT
    settings.detector_model_path = DET
    settings.frame_processing_interval = 4
    settings.max_target_lost_frames = 200
    settings.min_keypoint_confidence = 0.05
    settings.min_visible_core_joints = 1
    settings.min_detection_confidence = 0.25
    # Isolate acceptance gates per test session tmp artifact root
    for stage in ("A", "B", "C"):
        p = acceptance_path(settings, stage)  # type: ignore[arg-type]
        if p.exists():
            p.unlink()
    clear_model_cache()
    return settings


@pytest.fixture()
def detector():
    return RTMDetOnnxAdapter(DET)


def test_stage_b_blocked_without_a(pose_settings, detector):
    with pytest.raises(PoseStageError) as exc:
        run_pose_stage(
            settings=pose_settings,
            stage="B",
            job_id="blocked-b",
            video_id="blocked",
            source_path=FIX / "pose_stage_b_5s.mp4",
            detector=detector,
            write_acceptance=False,
        )
    assert exc.value.error_code == "POSE_STAGE_GATE"


def test_stage_a_still_image(pose_settings, detector):
    still = FIX / "pose_stage_a_still.jpg"
    if not still.is_file():
        still = FIX / "person_source.jpg"
    result = run_pose_stage(
        settings=pose_settings,
        stage="A",
        job_id="stage-a",
        video_id="still",
        source_path=still,
        detector=detector,
        write_acceptance=True,
    )
    assert result.status in {"completed", "completed_with_limitations"}
    assert Path(result.artifact_paths["raw_pose_json"]).is_file()
    payload = json.loads(Path(result.artifact_paths["raw_pose_json"]).read_text())
    assert payload["poses"]
    pose0 = payload["poses"][0]
    assert pose0["video_id"] == "still"
    assert pose0["job_id"] == "stage-a"
    assert len(pose0["keypoints"]) == 133
    assert acceptance_path(pose_settings, "A").is_file()
    assert result.average_inference_ms > 0


def test_stage_b_five_second_clip(pose_settings, detector):
    # Ensure A acceptance exists
    if not acceptance_path(pose_settings, "A").is_file():
        test_stage_a_still_image(pose_settings, detector)
    source = FIX / "pose_stage_b_5s.mp4"
    assert source.is_file()
    result = run_pose_stage(
        settings=pose_settings,
        stage="B",
        job_id="stage-b",
        video_id="five-sec",
        source_path=source,
        detector=detector,
        write_acceptance=True,
    )
    assert result.status in {"completed", "completed_with_limitations"}
    assert Path(result.artifact_paths["raw_pose_json"]).is_file()
    assert acceptance_path(pose_settings, "B").is_file()
    usable = [p for p in result.poses if p["usable"]]
    assert usable, "Stage B must produce at least one usable pose"


def test_stage_c_full_clip(pose_settings, detector):
    if not acceptance_path(pose_settings, "B").is_file():
        test_stage_b_five_second_clip(pose_settings, detector)
    source = FIX / "pose_stage_c_full.mp4"
    assert source.is_file()
    result = run_pose_stage(
        settings=pose_settings,
        stage="C",
        job_id="stage-c",
        video_id="full-clip",
        source_path=source,
        detector=detector,
        write_acceptance=True,
    )
    assert result.status in {"completed", "completed_with_limitations"}
    pose_path = Path(result.artifact_paths["raw_pose_json"])
    assert pose_path.is_file()
    payload = json.loads(pose_path.read_text())
    assert payload["model_name"] == "rtmpose-m-wholebody"
    assert "dependency_versions" in payload
    assert any(p.get("usable") for p in payload["poses"])
    # Failed/unusable frames explicitly identified
    assert "unusable_frames" in json.loads(
        Path(result.artifact_paths["unusable_frames_json"]).read_text()
    )

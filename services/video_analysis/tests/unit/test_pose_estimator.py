"""Unit tests for RTMPose WholeBody adapter and coordinate mapping."""

from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
import pytest

from app.models.rtmpose_adapter import RTMPoseWholeBodyAdapter, clear_model_cache
from app.services.pose_estimator import PoseEstimatorError

ROOT = Path(__file__).resolve().parents[2]
CFG = ROOT / "models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py"
CKPT = ROOT / (
    "models/rtmpose/"
    "rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth"
)
STILL = Path(__file__).resolve().parents[1] / "fixtures" / "person_source.jpg"


pytestmark = pytest.mark.skipif(
    not CFG.is_file() or not CKPT.is_file(),
    reason="RTMPose checkpoint/config missing",
)


@pytest.fixture()
def adapter():
    clear_model_cache()
    est = RTMPoseWholeBodyAdapter(
        config_path=CFG,
        checkpoint_path=CKPT,
        device="cpu",
    )
    est.load()
    return est


def test_model_loads_successfully(adapter):
    assert adapter.is_loaded()
    # Second load reuses cache
    adapter.load()
    assert adapter.is_loaded()


def test_still_image_inference(adapter):
    img = cv2.imread(str(STILL))
    assert img is not None
    h, w = img.shape[:2]
    crop = [w * 0.15, h * 0.05, w * 0.85, h * 0.95]
    est = adapter.estimate_crop(
        img,
        crop_xyxy=crop,
        video_id="v",
        job_id="j",
        frame_number=0,
        timestamp_ms=0.0,
        swimmer_track_id="t1",
        min_keypoint_confidence=0.05,
        min_visible_core_joints=1,
    )
    assert est.model_name == "rtmpose-m-wholebody"
    assert len(est.keypoints) == 133
    assert est.processing_duration_ms > 0
    # At least some keypoints should be present with low threshold
    assert any(k.x is not None for k in est.keypoints)


def test_coordinate_mapping_back_to_full_frame(adapter):
    img = cv2.imread(str(STILL))
    h, w = img.shape[:2]
    x1, y1, x2, y2 = w * 0.2, h * 0.1, w * 0.8, h * 0.9
    est = adapter.estimate_crop(
        img,
        crop_xyxy=[x1, y1, x2, y2],
        video_id="v",
        job_id="j",
        frame_number=0,
        timestamp_ms=0.0,
        swimmer_track_id="t1",
        min_keypoint_confidence=0.05,
        min_visible_core_joints=1,
    )
    for kp in est.keypoints:
        if kp.x is None:
            assert kp.x_crop is None
            continue
        assert kp.x_crop is not None and kp.y_crop is not None
        assert abs((kp.x_crop + x1) - kp.x) < 1e-3
        assert abs((kp.y_crop + y1) - kp.y) < 1e-3


def test_empty_crop(adapter):
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    est = adapter.estimate_crop(
        img,
        crop_xyxy=[10, 10, 10.5, 10.5],
        video_id="v",
        job_id="j",
        frame_number=1,
        timestamp_ms=33.0,
        swimmer_track_id="t1",
        min_keypoint_confidence=0.3,
        min_visible_core_joints=6,
    )
    assert est.usable is False
    assert est.unusable_reason == "empty_crop"
    assert all(k.x is None for k in est.keypoints)


def test_invalid_image(adapter):
    est = adapter.estimate_crop(
        None,
        crop_xyxy=[0, 0, 10, 10],
        video_id="v",
        job_id="j",
        frame_number=0,
        timestamp_ms=0.0,
        swimmer_track_id=None,
        min_keypoint_confidence=0.3,
        min_visible_core_joints=6,
    )
    assert est.usable is False
    assert est.unusable_reason == "invalid_image"


def test_missing_model_file():
    clear_model_cache()
    est = RTMPoseWholeBodyAdapter(
        config_path=CFG,
        checkpoint_path=ROOT / "models/rtmpose/does-not-exist.pth",
        device="cpu",
    )
    with pytest.raises(PoseEstimatorError) as exc:
        est.load()
    assert exc.value.error_code == "POSE_MODEL_MISSING"


def test_cpu_mode(adapter):
    assert "cpu" in str(adapter._device)


def test_unavailable_gpu_falls_back_in_builder(settings):
    from app.services.pose_pipeline import build_pose_estimator

    settings.pose_device = "cuda:0"
    settings.pose_config_path = CFG
    settings.pose_checkpoint_path = CKPT
    # Should not raise when CUDA missing; builder falls back to cpu.
    est = build_pose_estimator(settings)
    assert est.is_loaded()


def test_low_confidence_pose_null_landmarks(adapter):
    img = np.full((240, 320, 3), 255, dtype=np.uint8)
    est = adapter.estimate_crop(
        img,
        crop_xyxy=[20, 20, 300, 220],
        video_id="v",
        job_id="j",
        frame_number=0,
        timestamp_ms=0.0,
        swimmer_track_id="t",
        min_keypoint_confidence=0.99,
        min_visible_core_joints=6,
    )
    # High threshold forces null coordinates (do not invent landmarks)
    assert all(k.x is None for k in est.keypoints)
    assert est.usable is False or "low_confidence_pose" in est.quality_flags or not est.usable

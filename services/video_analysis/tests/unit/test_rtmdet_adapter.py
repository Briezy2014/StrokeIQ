from pathlib import Path

import cv2
import numpy as np
import pytest

from app.models.rtmdet_adapter import RTMDetOnnxAdapter

MODEL = Path(__file__).resolve().parents[2] / "models" / "rtmdet-n-person.onnx"
PERSON = Path(__file__).resolve().parents[1] / "fixtures" / "person_source.jpg"


@pytest.mark.skipif(not MODEL.is_file(), reason="RTMDet ONNX model not downloaded")
def test_rtmdet_detects_person_image():
    if not PERSON.is_file():
        pytest.skip("person fixture image missing")
    img = cv2.imread(str(PERSON))
    assert img is not None
    adapter = RTMDetOnnxAdapter(MODEL)
    dets = adapter.detect(img, frame_number=0, timestamp_ms=0.0, min_confidence=0.35)
    assert len(dets) >= 1
    assert dets[0].model_name == "rtmdet-n-person"
    assert dets[0].temporary_detection_id
    assert dets[0].bbox.area > 0

"""Model weight registry."""

from __future__ import annotations

from pathlib import Path

KNOWN_MODELS = {
    "detector": {
        "name": "rtmdet-n-person",
        "version": "onnx-1.0-openmmlab-rtmdet",
        "license": "Apache-2.0",
        "default_path": "models/rtmdet-n-person.onnx",
    },
    "pose": {
        "name": "rtmpose-m-wholebody",
        "version": "mmpose-1.3.2-rtmpose-m-coco-wholebody-256x192",
        "license": "Apache-2.0",
        "config": "models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py",
        "checkpoint": (
            "models/rtmpose/"
            "rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth"
        ),
        "keypoints": 133,
    },
}


def list_registered_models() -> dict:
    return dict(KNOWN_MODELS)


def resolve_detector_model_path(configured: str | Path) -> Path:
    path = Path(configured)
    if path.is_file():
        return path
    service_root = Path(__file__).resolve().parents[2]
    alt = service_root / configured
    if alt.is_file():
        return alt
    return path

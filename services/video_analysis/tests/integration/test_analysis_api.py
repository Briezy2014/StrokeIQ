from __future__ import annotations

import json
import time
from pathlib import Path

from app.api.schemas.responses import JobStatus
from app.models.scripted_detector import ScriptedDetectorAdapter

FIX = Path(__file__).resolve().parents[1] / "fixtures"


def _wait_terminal(client, job_id: str, timeout_s: float = 30.0) -> dict:
    deadline = time.time() + timeout_s
    status = {}
    while time.time() < deadline:
        status = client.get(f"/v1/analyses/{job_id}").json()
        if status["status"] in {
            JobStatus.completed.value,
            JobStatus.completed_with_limitations.value,
            JobStatus.failed.value,
        }:
            return status
        time.sleep(0.05)
    raise AssertionError(f"Job {job_id} did not finish in time: {status}")


def test_create_and_complete_with_scripted_detector(client, settings):
    script_path = FIX / "multi_swimmer_script.json"
    raw = json.loads(script_path.read_text())
    script = {
        int(k): [(list(map(float, box)), float(conf)) for box, conf in items]
        for k, items in raw.items()
    }
    client.app.state.detector = ScriptedDetectorAdapter(script)
    settings.max_target_lost_frames = 80
    client.app.state.settings = settings

    create = client.post(
        "/v1/analyses",
        json={
            "video_id": "vid-multi-api",
            "local_path": str(FIX / "multi_swimmer_synth.mp4"),
            "athlete": {"swimmer_key": "aspyn", "display_name": "Aspyn"},
            "event": {"stroke": "butterfly", "distance_m": 50, "course": "LCM"},
            "options": {"target_selection_mode": "automatic", "generate_gemini_report": False},
        },
    )
    assert create.status_code == 202, create.text
    job_id = create.json()["job_id"]
    status = _wait_terminal(client, job_id)
    assert status["status"] in {
        JobStatus.completed.value,
        JobStatus.completed_with_limitations.value,
    }

    results = client.get(f"/v1/analyses/{job_id}/results")
    assert results.status_code == 200
    body = results.json()
    assert body["report"] is None
    assert body["metrics"] == []
    assert body["tracking"] is not None
    assert body["tracking"]["target"]["track_id"]
    assert body["model_versions"]["milestone"] == "2"
    annotated = body["tracking"]["artifact_paths"]["annotated_tracking_video"]
    assert annotated and Path(annotated).is_file()


def test_corrupt_video_fails(client, corrupt_video: Path):
    create = client.post(
        "/v1/analyses",
        json={"video_id": "vid-corrupt", "local_path": str(corrupt_video)},
    )
    assert create.status_code == 202
    job_id = create.json()["job_id"]
    status = _wait_terminal(client, job_id)
    assert status["status"] == JobStatus.failed.value
    assert status["error"] is not None
    results = client.get(f"/v1/analyses/{job_id}/results")
    assert results.status_code == 200
    body = results.json()
    assert body["status"] == "failed"
    assert body["report"] is None


def test_empty_blue_video_no_placeholder_success(client, valid_video: Path):
    """Solid-color clip has no people — must fail, not invent tracking success."""
    create = client.post(
        "/v1/analyses",
        json={"video_id": "vid-empty", "local_path": str(valid_video)},
    )
    assert create.status_code == 202
    status = _wait_terminal(client, create.json()["job_id"], timeout_s=60)
    assert status["status"] == JobStatus.failed.value
    assert status["error"]["error_code"] in {
        "NO_DETECTIONS",
        "DETECTOR_MODEL_MISSING",
        "TARGET_LOST_EXTENDED",
    }


def test_missing_path_rejected(client):
    response = client.post("/v1/analyses", json={"video_id": "x"})
    assert response.status_code == 400


def test_cancel_job(client, settings):
    script = {i: [([20, 20, 60, 60], 0.9)] for i in range(200)}
    client.app.state.detector = ScriptedDetectorAdapter(script)
    client.app.state.settings = settings
    create = client.post(
        "/v1/analyses",
        json={
            "video_id": "vid-cancel",
            "local_path": str(FIX / "multi_swimmer_synth.mp4"),
        },
    )
    job_id = create.json()["job_id"]
    cancel = client.post(f"/v1/analyses/{job_id}/cancel")
    assert cancel.status_code in {200, 409}

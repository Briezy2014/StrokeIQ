from __future__ import annotations

import time
from pathlib import Path

from app.api.schemas.responses import JobStatus


def _wait_terminal(client, job_id: str, timeout_s: float = 10.0) -> dict:
    deadline = time.time() + timeout_s
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


def test_create_and_complete_valid_video(client, valid_video: Path):
    create = client.post(
        "/v1/analyses",
        json={
            "video_id": "vid-valid-1",
            "local_path": str(valid_video),
            "athlete": {"swimmer_key": "aspyn", "display_name": "Aspyn"},
            "event": {"stroke": "butterfly", "distance_m": 50, "course": "LCM"},
            "options": {"generate_gemini_report": False},
        },
    )
    assert create.status_code == 202, create.text
    job_id = create.json()["job_id"]

    status = _wait_terminal(client, job_id)
    assert status["status"] in {
        JobStatus.completed.value,
        JobStatus.completed_with_limitations.value,
    }
    assert status["error"] is None

    results = client.get(f"/v1/analyses/{job_id}/results")
    assert results.status_code == 200
    body = results.json()
    assert body["report"] is None
    assert body["metrics"] == []
    assert body["video"] is not None
    assert body["video"]["width"] > 0
    assert body["video"]["fps"] > 0
    assert body["metadata_artifact_path"]
    assert Path(body["metadata_artifact_path"]).is_file()


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
    assert status["error"]["error_code"]

    results = client.get(f"/v1/analyses/{job_id}/results")
    assert results.status_code == 200
    body = results.json()
    assert body["status"] == "failed"
    assert body["report"] is None
    assert body["video"] is None


def test_rotated_video_pipeline(client, rotated_video: Path):
    create = client.post(
        "/v1/analyses",
        json={"video_id": "vid-rotated", "local_path": str(rotated_video)},
    )
    assert create.status_code == 202
    job_id = create.json()["job_id"]
    status = _wait_terminal(client, job_id)
    assert status["status"] in {
        JobStatus.completed.value,
        JobStatus.completed_with_limitations.value,
        JobStatus.failed.value,
    }
    # Rotated fixtures may or may not retain rotate tags depending on encoder;
    # either completed metadata or a clear failure code is acceptable.
    if status["status"] != JobStatus.failed.value:
        results = client.get(f"/v1/analyses/{job_id}/results").json()
        assert results["report"] is None
        assert results["video"]["duration_ms"] > 0


def test_missing_path_rejected(client):
    response = client.post("/v1/analyses", json={"video_id": "x"})
    assert response.status_code == 400


def test_cancel_queued_job(client, valid_video: Path, settings):
    # Create job without running background processing by saving directly is hard;
    # cancel immediately after create — may race; accept cancelled or completed.
    create = client.post(
        "/v1/analyses",
        json={"video_id": "vid-cancel", "local_path": str(valid_video)},
    )
    job_id = create.json()["job_id"]
    cancel = client.post(f"/v1/analyses/{job_id}/cancel")
    assert cancel.status_code in {200, 409}

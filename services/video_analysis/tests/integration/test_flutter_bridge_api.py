"""Milestone 9 backend integration tests (auth, jobs, RLS-shaped access, signed URLs)."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.domain.jobs import AnalysisJob, new_job_id
from app.main import app
from app.api.schemas.responses import JobStatus
from app.services.result_store import ResultStore


def _force_status(job: AnalysisJob, status: JobStatus, *, progress: float = 1.0) -> None:
    job.status = status
    job.stage = status.value
    job.progress = progress


@pytest.fixture()
def api_client(tmp_path: Path):
    get_settings.cache_clear()
    settings = Settings(
        engine_version="elote-0.9.0-test",
        artifact_root=tmp_path / "artifacts",
        job_store_path=tmp_path / "artifacts" / "jobs.json",
        supabase_auth_required=False,
        supabase_persist_results=False,
        supabase_url="https://example.supabase.co",
        supabase_anon_key="anon",
        supabase_service_role_key="service",
        video_engine_name="video_engine_v2",
    )
    settings.ensure_dirs()
    store = ResultStore(settings.job_store_path)
    with TestClient(app) as client:
        client.app.state.settings = settings
        client.app.state.store = store
        client.app.state.detector = None
        yield client, store, settings
    get_settings.cache_clear()


def test_create_job_authenticated(api_client, valid_video: Path):
    client, store, _ = api_client
    resp = client.post(
        "/v1/analyses",
        json={
            "video_id": "11111111-1111-1111-1111-111111111111",
            "local_path": str(valid_video),
            "storage_bucket": "swim-videos",
            "storage_path": "athlete/clip.mp4",
            "athlete": {"swimmer_key": "alex"},
            "event": {"stroke": "butterfly", "distance_m": 50, "course": "SCY"},
            "options": {"generate_gemini_report": False},
        },
    )
    assert resp.status_code == 202, resp.text
    body = resp.json()
    assert body["status"] == "queued"
    job = store.get(body["job_id"])
    assert job is not None
    assert job.owner_user_id == "local-dev-user"
    assert job.swimmer_key == "alex"
    assert job.model_versions.get("engine_name") == "video_engine_v2"


def test_status_updates_and_results_retrieval(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-1",
        engine_version=settings.engine_version,
        request_payload={"athlete": {"swimmer_key": "alex"}},
    )
    job.owner_user_id = "local-dev-user"
    job.swimmer_key = "alex"
    job.butterfly = {
        "metrics": [
            {
                "name": "stroke_rate",
                "value": 48.0,
                "unit": "strokes/min",
                "confidence": 0.9,
                "confidence_label": "high",
                "classification": "estimated",
            }
        ],
        "events": [],
    }
    _force_status(job, JobStatus.completed)
    store.save(job)

    status = client.get(f"/v1/analyses/{job.job_id}")
    assert status.status_code == 200
    assert status.json()["stage"] == "completed"

    results = client.get(f"/v1/analyses/{job.job_id}/results")
    assert results.status_code == 200
    data = results.json()
    assert any(m["name"] == "stroke_rate" for m in data["metrics"])
    assert data["report"] is None  # Gemini not required for deterministic results


def test_unauthorized_result_access(api_client):
    _, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-2",
        engine_version=settings.engine_version,
        request_payload={},
    )
    job.owner_user_id = "someone-else"
    _force_status(job, JobStatus.completed)
    store.save(job)

    from app.api.ownership import assert_can_access
    from app.auth.supabase_auth import AuthUser
    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc:
        assert_can_access(job, AuthUser(user_id="caller"))
    assert exc.value.status_code == 403
    assert exc.value.detail["error_code"] == "UNAUTHORIZED_RESULT_ACCESS"


def test_report_retrieval_when_present(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-3",
        engine_version=settings.engine_version,
        request_payload={},
    )
    job.owner_user_id = "local-dev-user"
    job.report = {
        "gemini_succeeded": True,
        "report": {
            "status": "validated",
            "summary": "Steady butterfly rhythm.",
            "model_name": "gemini-2.5-flash",
        },
    }
    job.butterfly = {"metrics": [{"name": "stroke_rate", "value": 40, "unit": "strokes/min"}], "events": []}
    _force_status(job, JobStatus.completed_with_limitations)
    store.save(job)
    results = client.get(f"/v1/analyses/{job.job_id}/results")
    assert results.status_code == 200
    assert results.json()["report"]["summary"] == "Steady butterfly rhythm."
    assert results.json()["metrics"]


def test_nested_stored_coaching_report_is_flattened_for_flutter(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-3b",
        engine_version=settings.engine_version,
        request_payload={},
    )
    job.owner_user_id = "local-dev-user"
    job.report = {
        "gemini_succeeded": True,
        "report": {
            "status": "validated",
            "model_name": "gemini-2.5-flash",
            "report": {
                "summary": "Nested body summary for the coach.",
                "strengths": [
                    {
                        "text": "Steady rhythm through the middle of the pool.",
                        "confidence_band": "moderate",
                        "metric_ids": ["tracking:target_coverage"],
                        "event_ids": [],
                    }
                ],
                "priority_improvements": [
                    {
                        "observation": {
                            "text": "Keep the camera side-on for clearer review.",
                            "confidence_band": "moderate",
                            "metric_ids": ["tracking:target_coverage"],
                            "event_ids": [],
                        },
                        "drills": ["Film one length from the side."],
                    }
                ],
                "limitations": ["Depends on video quality and camera angle."],
                "confidence_statement": "Confidence follows tracking visibility on this clip.",
                "disclaimer": "Tips depend on video quality and camera angle.",
            },
        },
    }
    _force_status(job, JobStatus.completed)
    store.save(job)
    results = client.get(f"/v1/analyses/{job.job_id}/results")
    assert results.status_code == 200
    report = results.json()["report"]
    assert report["summary"] == "Nested body summary for the coach."
    assert report["strengths"] == ["Steady rhythm through the middle of the pool."]
    assert report["priority_improvements"][0]["title"].startswith("Keep the camera")
    assert report["gemini_succeeded"] is True


def test_gemini_failure_keeps_deterministic_metrics(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-4",
        engine_version=settings.engine_version,
        request_payload={},
    )
    job.owner_user_id = "local-dev-user"
    job.report = {
        "gemini_succeeded": False,
        "report": {"status": "failed", "failure_code": "MISSING_API_KEY"},
        "limitations": ["gemini_report_failed:MISSING_API_KEY"],
    }
    job.limitations = ["gemini_report_failed:MISSING_API_KEY"]
    job.butterfly = {
        "metrics": [
            {
                "name": "stroke_rate",
                "value": 42,
                "unit": "strokes/min",
                "confidence_label": "high",
                "classification": "estimated",
            }
        ]
    }
    _force_status(job, JobStatus.completed_with_limitations)
    store.save(job)
    results = client.get(f"/v1/analyses/{job.job_id}/results").json()
    assert results["metrics"]
    assert results["report"]["status"] == "failed"


def test_delete_and_feedback(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-5",
        engine_version=settings.engine_version,
        request_payload={},
    )
    job.owner_user_id = "local-dev-user"
    _force_status(job, JobStatus.completed)
    store.save(job)

    fb = client.post(
        f"/v1/analyses/{job.job_id}/feedback",
        json={"feedback_type": "incorrect_result", "message": "Breakout looks early"},
    )
    assert fb.status_code == 200

    deleted = client.delete(f"/v1/analyses/{job.job_id}")
    assert deleted.status_code == 200
    assert store.get(job.job_id).status == JobStatus.cancelled


def test_signed_artifact_access_mocked(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-6",
        engine_version=settings.engine_version,
        request_payload={},
        storage_bucket="swim-videos",
        storage_path="alex/clip.mp4",
    )
    job.owner_user_id = "local-dev-user"
    _force_status(job, JobStatus.completed)
    store.save(job)

    with patch(
        "app.api.routes.flutter_bridge.SupabaseBridge.create_signed_url",
        return_value="https://example.supabase.co/storage/v1/object/sign/swim-videos/alex/clip.mp4?token=abc",
    ):
        resp = client.get(f"/v1/analyses/{job.job_id}/signed-video-url")
    assert resp.status_code == 200
    assert "signed_url" in resp.json()
    assert resp.json()["storage_path"] == "alex/clip.mp4"


def test_history_list(api_client):
    client, store, settings = api_client
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="vid-7",
        engine_version=settings.engine_version,
        request_payload={"athlete": {"swimmer_key": "alex"}},
    )
    job.owner_user_id = "local-dev-user"
    job.swimmer_key = "alex"
    _force_status(job, JobStatus.completed)
    store.save(job)
    resp = client.get("/v1/athletes/alex/analyses")
    assert resp.status_code == 200
    assert any(j["job_id"] == job.job_id for j in resp.json()["jobs"])


def test_rls_policy_sql_present():
    sql = Path("/workspace/swimiq/supabase/migrations/005_video_analysis_engine_v2.sql").read_text()
    for table in [
        "video_analysis_jobs",
        "video_analysis_metrics",
        "video_analysis_events",
        "video_analysis_reports",
        "video_analysis_artifacts",
        "video_analysis_feedback",
        "model_versions",
    ]:
        assert table in sql
    assert "ROW LEVEL SECURITY" in sql
    assert "user_can_access_analysis_job" in sql

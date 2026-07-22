"""Unit tests for recruiting highlight clip pack + auto-stitched reel."""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.main import app
from app.services.highlight_reel import (
    build_highlight_reel,
    resolve_window,
    sort_segments,
)
from app.services.result_store import ResultStore


@pytest.fixture()
def api_client(tmp_path: Path):
    get_settings.cache_clear()
    settings = Settings(
        engine_version="elote-0.9.0-test",
        artifact_root=tmp_path / "artifacts",
        job_store_path=tmp_path / "artifacts" / "jobs.json",
        supabase_auth_required=False,
        supabase_persist_results=False,
        ffmpeg_path="ffmpeg",
        ffprobe_path="ffprobe",
    )
    settings.ensure_dirs()
    store = ResultStore(settings.job_store_path)
    with TestClient(app) as client:
        client.app.state.settings = settings
        client.app.state.store = store
        client.app.state.detector = None
        yield client, settings
    get_settings.cache_clear()


def test_resolve_window_caps_and_keeps_finish_edge():
    start, end = resolve_window(
        tag="Sprint finish",
        duration_ms=20_000,
        start_ms=0,
        end_ms=20_000,
        max_clip_ms=4000,
    )
    assert end == 20_000
    assert end - start == 4000


def test_sort_segments_sales_order():
    ordered = sort_segments(
        [
            {"tag": "Race", "label": "A"},
            {"tag": "Best start", "label": "B"},
            {"tag": "Best finish", "label": "C"},
        ]
    )
    assert [s["tag"] for s in ordered] == ["Best start", "Best finish", "Race"]


def test_build_and_download_highlight_reel(api_client, valid_video: Path):
    client, settings = api_client
    assert valid_video.exists()

    built = build_highlight_reel(
        settings=settings,
        segments=[
            {
                "tag": "Best start",
                "label": "Fly 2",
                "local_path": str(valid_video),
            },
            {
                "tag": "Sprint finish",
                "label": "Fly 2",
                "local_path": str(valid_video),
            },
        ],
        source_resolver=lambda seg: Path(seg["local_path"]),
        max_clip_ms=3000,
        title="Test Reel",
    )
    assert built["reel_path"].exists()
    assert built["reel_path"].stat().st_size > 500
    assert len(built["clips"]) == 2

    resp = client.post(
        "/v1/highlight-reels",
        json={
            "title": "Aspyn Recruiting Reel",
            "max_clip_ms": 3000,
            "segments": [
                {
                    "tag": "Best start",
                    "label": "Fly 2",
                    "local_path": str(valid_video),
                },
                {
                    "tag": "Best turn",
                    "label": "Denison 50 Fly",
                    "local_path": str(valid_video),
                },
            ],
        },
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["reel_id"]
    assert body["download_token"]
    assert body["reel_url"].endswith(f"token={body['download_token']}")
    assert len(body["clips"]) == 2

    reel = client.get(body["reel_url"])
    assert reel.status_code == 200
    assert reel.headers["content-type"].startswith("video/")
    assert len(reel.content) > 500

    clip = client.get(body["clips"][0]["download_url"])
    assert clip.status_code == 200
    assert len(clip.content) > 500

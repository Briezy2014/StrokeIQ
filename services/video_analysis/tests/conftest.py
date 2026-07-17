"""Shared pytest fixtures for the analysis service."""

from __future__ import annotations

from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.main import app
from app.services.result_store import ResultStore

FIXTURES = Path(__file__).resolve().parent / "fixtures"
MODEL = Path(__file__).resolve().parents[1] / "models" / "rtmdet-n-person.onnx"


@pytest.fixture()
def fixtures_dir() -> Path:
    return FIXTURES


@pytest.fixture()
def valid_video(fixtures_dir: Path) -> Path:
    return fixtures_dir / "valid_short.mp4"


@pytest.fixture()
def corrupt_video(fixtures_dir: Path) -> Path:
    return fixtures_dir / "corrupt.mp4"


@pytest.fixture()
def rotated_video(fixtures_dir: Path) -> Path:
    return fixtures_dir / "rotated_phone.mp4"


@pytest.fixture()
def settings(tmp_path: Path) -> Settings:
    s = Settings(
        engine_version="elote-0.2.0-test",
        artifact_root=tmp_path / "artifacts",
        job_store_path=tmp_path / "artifacts" / "jobs.json",
        max_video_bytes=10_000_000,
        min_width=160,
        min_height=120,
        min_fps=10.0,
        min_duration_ms=100,
        ffprobe_path="ffprobe",
        ffmpeg_path="ffmpeg",
        log_level="WARNING",
        detector_backend="rtmdet_onnx",
        detector_model_path=MODEL if MODEL.is_file() else Path("models/rtmdet-n-person.onnx"),
        min_detection_confidence=0.35,
        tracking_confidence_threshold=0.40,
        max_lost_frames=15,
        max_target_lost_frames=60,
        frame_processing_interval=1,
        inference_resolution=320,
        max_active_tracks=12,
    )
    s.ensure_dirs()
    return s


@pytest.fixture()
def client(settings: Settings):
    get_settings.cache_clear()
    store = ResultStore(settings.job_store_path)

    with TestClient(app) as test_client:
        test_client.app.state.settings = settings
        test_client.app.state.store = store
        test_client.app.state.detector = None
        yield test_client

    get_settings.cache_clear()

"""Environment-driven settings for the Elote Video Lab analysis service."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    engine_version: str = "elote-0.2.0"
    artifact_root: Path = Path("./analysis_artifacts")
    job_store_path: Path = Path("./analysis_artifacts/jobs.json")
    max_video_bytes: int = 524_288_000  # 500 MiB
    min_width: int = 320
    min_height: int = 240
    min_fps: float = 15.0
    min_duration_ms: int = 200
    ffprobe_path: str = "ffprobe"
    ffmpeg_path: str = "ffmpeg"
    log_level: str = "INFO"

    # Milestone 2 — detection / tracking
    detector_backend: str = "rtmdet_onnx"
    detector_model_path: Path = Path("models/rtmdet-n-person.onnx")
    min_detection_confidence: float = 0.35
    tracking_confidence_threshold: float = 0.40
    max_lost_frames: int = 15
    max_target_lost_frames: int = 45
    frame_processing_interval: int = 1
    inference_resolution: int = 320
    max_active_tracks: int = 12

    def ensure_dirs(self) -> None:
        self.artifact_root.mkdir(parents=True, exist_ok=True)
        self.job_store_path.parent.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.ensure_dirs()
    return settings

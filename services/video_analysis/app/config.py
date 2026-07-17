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

    engine_version: str = "elote-0.1.0"
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

    def ensure_dirs(self) -> None:
        self.artifact_root.mkdir(parents=True, exist_ok=True)
        self.job_store_path.parent.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.ensure_dirs()
    return settings

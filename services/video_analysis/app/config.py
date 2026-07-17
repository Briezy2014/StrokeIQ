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

    engine_version: str = "elote-0.7.0"
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

    # Milestone 3 — RTMPose WholeBody
    pose_enabled: bool = False
    pose_stage: str = "A"  # A | B | C — never auto-advance
    pose_device: str = "cpu"  # cpu | cuda:0 | auto
    pose_config_path: Path = Path(
        "models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py"
    )
    pose_checkpoint_path: Path = Path(
        "models/rtmpose/rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth"
    )
    pose_input_width: int = 192
    pose_input_height: int = 256
    min_keypoint_confidence: float = 0.30
    min_visible_core_joints: int = 6

    # Milestone 4 — pose validation / temporal smoothing / diagnostics
    pose_smoothing_enabled: bool = True
    max_interpolation_gap_frames: int = 3
    max_joint_velocity_px_s: float = 2500.0
    max_joint_acceleration_px_s2: float = 80000.0
    continuity_max_jump_px: float = 100.0
    savgol_window: int = 5
    savgol_polyorder: int = 2
    long_occlusion_gap_frames: int = 8
    usable_frame_min_core_joints: int = 4
    usable_frame_min_confidence: float = 0.20
    overlay_min_draw_confidence: float = 0.25
    diagnostic_frame_count: int = 12

    # Milestone 5 — butterfly surface-stroke analysis
    butterfly_analysis_enabled: bool = False
    butterfly_min_cycle_duration_s: float = 0.70
    butterfly_max_cycle_duration_s: float = 2.20
    butterfly_min_peak_prominence: float = 0.08
    butterfly_min_bilateral_sync: float = 0.25
    pool_distance_calibrated: bool = False

    # Milestone 6 — underwater / dolphin-kick / breakout
    underwater_analysis_enabled: bool = False
    underwater_min_kick_interval_s: float = 0.28
    underwater_max_kick_interval_s: float = 1.10
    underwater_kick_prominence_px: float = 4.0
    underwater_min_duration_s: float = 0.40

    # Milestone 7 — turn / finish event framework
    turn_analysis_enabled: bool = False
    finish_analysis_enabled: bool = False

    def ensure_dirs(self) -> None:
        self.artifact_root.mkdir(parents=True, exist_ok=True)
        self.job_store_path.parent.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.ensure_dirs()
    return settings

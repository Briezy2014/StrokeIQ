from pathlib import Path

import pytest

from app.services.video_validator import VideoValidationError, validate_video


def test_validate_valid_short(settings, valid_video: Path):
    result = validate_video(valid_video, settings)
    assert result.width >= 160
    assert result.height >= 120
    assert result.fps >= 10
    assert result.duration_ms >= 100
    assert result.codec is not None
    assert result.file_size_bytes > 0


def test_validate_corrupt(settings, corrupt_video: Path):
    with pytest.raises(VideoValidationError) as exc:
        validate_video(corrupt_video, settings)
    assert exc.value.error_code in {
        "UNREADABLE_STREAM",
        "NO_VIDEO_STREAM",
        "UNSUPPORTED_CODEC",
    }


def test_validate_missing(settings, tmp_path: Path):
    with pytest.raises(VideoValidationError) as exc:
        validate_video(tmp_path / "missing.mp4", settings)
    assert exc.value.error_code == "VIDEO_NOT_FOUND"


def test_validate_too_large(settings, valid_video: Path):
    settings.max_video_bytes = 10
    with pytest.raises(VideoValidationError) as exc:
        validate_video(valid_video, settings)
    assert exc.value.error_code == "VIDEO_TOO_LARGE"

"""ffprobe-based video validation for Milestone 1."""

from __future__ import annotations

import json
import mimetypes
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from app.config import Settings
from app.utils.timestamps import seconds_to_ms


class VideoValidationError(Exception):
    def __init__(self, error_code: str, message: str, *, retriable: bool = False) -> None:
        super().__init__(message)
        self.error_code = error_code
        self.message = message
        self.retriable = retriable


@dataclass
class ValidatedVideo:
    path: Path
    file_size_bytes: int
    duration_ms: int
    fps: float
    width: int
    height: int
    frame_count: int | None
    codec: str | None
    mime_type: str | None
    rotation: int
    quality_flags: list[str] = field(default_factory=list)
    raw_ffprobe: dict[str, Any] = field(default_factory=dict)


def _run_ffprobe(ffprobe_path: str, video_path: Path) -> dict[str, Any]:
    cmd = [
        ffprobe_path,
        "-v",
        "error",
        "-print_format",
        "json",
        "-show_format",
        "-show_streams",
        str(video_path),
    ]
    try:
        completed = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=20,
        )
    except subprocess.TimeoutExpired as exc:
        raise VideoValidationError(
            "FFPROBE_TIMEOUT",
            "Video validation timed out while reading this file. "
            "Re-upload the clip as MP4 (H.264) and try again.",
            retriable=True,
        ) from exc
    except FileNotFoundError as exc:
        raise VideoValidationError(
            "FFPROBE_UNAVAILABLE",
            f"ffprobe not found at '{ffprobe_path}'",
            retriable=False,
        ) from exc

    if completed.returncode != 0:
        err = (completed.stderr or completed.stdout or "ffprobe failed").strip()
        raise VideoValidationError(
            "UNREADABLE_STREAM",
            f"ffprobe could not read video: {err}",
            retriable=False,
        )

    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise VideoValidationError(
            "UNREADABLE_STREAM",
            "ffprobe returned invalid JSON metadata",
            retriable=False,
        ) from exc


def _parse_fps(stream: dict[str, Any]) -> float:
    for key in ("avg_frame_rate", "r_frame_rate"):
        value = stream.get(key)
        if not value or value == "0/0":
            continue
        if "/" in value:
            num_s, den_s = value.split("/", 1)
            num = float(num_s)
            den = float(den_s)
            if den == 0:
                continue
            return num / den
        try:
            return float(value)
        except ValueError:
            continue
    return 0.0


def _parse_rotation(stream: dict[str, Any], format_tags: dict[str, Any]) -> int:
    tags = stream.get("tags") or {}
    rotate = tags.get("rotate") or format_tags.get("rotate")
    if rotate is not None:
        try:
            return int(float(rotate)) % 360
        except (TypeError, ValueError):
            pass

    for side_data in stream.get("side_data_list") or []:
        if "rotation" in side_data:
            try:
                return int(float(side_data["rotation"])) % 360
            except (TypeError, ValueError):
                continue
    return 0


def _guess_mime(path: Path, codec: str | None) -> str | None:
    mime, _ = mimetypes.guess_type(str(path))
    if mime:
        return mime
    if codec in {"h264", "hevc", "mpeg4"}:
        return "video/mp4"
    if codec == "vp8" or codec == "vp9":
        return "video/webm"
    return None


def validate_video(path: Path, settings: Settings) -> ValidatedVideo:
    if not path.exists() or not path.is_file():
        raise VideoValidationError(
            "VIDEO_NOT_FOUND",
            f"Video file not found: {path}",
            retriable=False,
        )

    file_size = path.stat().st_size
    if file_size <= 0:
        raise VideoValidationError(
            "EMPTY_FILE",
            "Video file is empty",
            retriable=False,
        )
    if file_size > settings.max_video_bytes:
        raise VideoValidationError(
            "VIDEO_TOO_LARGE",
            f"Video exceeds max size of {settings.max_video_bytes} bytes",
            retriable=False,
        )

    probe = _run_ffprobe(settings.ffprobe_path, path)
    streams = probe.get("streams") or []
    video_streams = [s for s in streams if s.get("codec_type") == "video"]
    if not video_streams:
        raise VideoValidationError(
            "NO_VIDEO_STREAM",
            "No video stream found in file",
            retriable=False,
        )

    stream = video_streams[0]
    codec = stream.get("codec_name")
    if not codec:
        raise VideoValidationError(
            "UNSUPPORTED_CODEC",
            "Video stream codec could not be determined",
            retriable=False,
        )

    width = int(stream.get("width") or 0)
    height = int(stream.get("height") or 0)
    if width < settings.min_width or height < settings.min_height:
        raise VideoValidationError(
            "RESOLUTION_TOO_LOW",
            f"Resolution {width}x{height} below minimum "
            f"{settings.min_width}x{settings.min_height}",
            retriable=False,
        )

    fps = _parse_fps(stream)
    if fps < settings.min_fps:
        raise VideoValidationError(
            "FPS_TOO_LOW",
            f"Frame rate {fps:.3f} below minimum {settings.min_fps}",
            retriable=False,
        )

    fmt = probe.get("format") or {}
    duration_s = float(fmt.get("duration") or stream.get("duration") or 0.0)
    duration_ms = seconds_to_ms(duration_s)
    if duration_ms < settings.min_duration_ms:
        raise VideoValidationError(
            "DURATION_TOO_SHORT",
            f"Duration {duration_ms}ms below minimum {settings.min_duration_ms}ms",
            retriable=False,
        )

    nb_frames = stream.get("nb_frames")
    frame_count: int | None
    try:
        frame_count = int(nb_frames) if nb_frames not in (None, "N/A") else None
    except (TypeError, ValueError):
        frame_count = None
    if frame_count is None and fps > 0 and duration_s > 0:
        frame_count = int(round(fps * duration_s))

    format_tags = fmt.get("tags") or {}
    rotation = _parse_rotation(stream, format_tags)
    mime_type = _guess_mime(path, codec)

    quality_flags: list[str] = []
    if rotation not in (0, None):
        quality_flags.append("rotation_metadata_present")

    avg_fps = _parse_fps({"avg_frame_rate": stream.get("avg_frame_rate")})
    r_fps = _parse_fps({"r_frame_rate": stream.get("r_frame_rate")})
    if avg_fps > 0 and r_fps > 0 and abs(avg_fps - r_fps) / max(avg_fps, r_fps) > 0.05:
        quality_flags.append("variable_frame_rate_suspected")

    return ValidatedVideo(
        path=path.resolve(),
        file_size_bytes=file_size,
        duration_ms=duration_ms,
        fps=fps,
        width=width,
        height=height,
        frame_count=frame_count,
        codec=codec,
        mime_type=mime_type,
        rotation=rotation,
        quality_flags=quality_flags,
        raw_ffprobe=probe,
    )

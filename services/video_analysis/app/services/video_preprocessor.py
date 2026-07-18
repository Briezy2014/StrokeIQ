"""Normalize rotation metadata and persist Milestone 1 artifacts."""

from __future__ import annotations

import json
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from app.config import Settings
from app.services.video_validator import ValidatedVideo, VideoValidationError


@dataclass
class PreprocessResult:
    original_path: str
    normalized_path: str | None
    proxy_path: str | None
    metadata_path: str
    metadata: dict[str, Any]
    limitations: list[str]


def artifact_dir(settings: Settings, job_id: str) -> Path:
    path = settings.artifact_root / job_id
    path.mkdir(parents=True, exist_ok=True)
    (path / "frames").mkdir(exist_ok=True)
    (path / "pose").mkdir(exist_ok=True)
    (path / "events").mkdir(exist_ok=True)
    (path / "results").mkdir(exist_ok=True)
    return path


def _normalize_rotation(
    *,
    settings: Settings,
    validated: ValidatedVideo,
    out_path: Path,
) -> str | None:
    """Correct rotation when metadata is present; preserve original always."""
    if validated.rotation in (0, None):
        return None

    cmd = [
        settings.ffmpeg_path,
        "-y",
        "-i",
        str(validated.path),
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-c:a",
        "copy",
        # Do not force 1 fps — keep source frame rate.
        "-vsync",
        "cfr",
        str(out_path),
    ]
    try:
        completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        raise VideoValidationError(
            "FFMPEG_UNAVAILABLE",
            f"ffmpeg not found at '{settings.ffmpeg_path}'",
            retriable=False,
        ) from exc

    if completed.returncode != 0 or not out_path.exists():
        err = (completed.stderr or completed.stdout or "ffmpeg failed").strip()
        raise VideoValidationError(
            "PREPROCESS_FAILED",
            f"ffmpeg normalization failed: {err}",
            retriable=True,
        )
    return str(out_path.resolve())


def preprocess_video(
    *,
    settings: Settings,
    job_id: str,
    video_id: str,
    validated: ValidatedVideo,
    view_hint: str = "unknown",
) -> PreprocessResult:
    root = artifact_dir(settings, job_id)
    limitations: list[str] = []

    normalized_path: str | None = None
    if validated.rotation not in (0, None):
        normalized_file = root / "normalized.mp4"
        try:
            normalized_path = _normalize_rotation(
                settings=settings,
                validated=validated,
                out_path=normalized_file,
            )
        except VideoValidationError:
            raise
        limitations.append(
            "Source video had rotation metadata; normalized copy written. "
            "Original file preserved."
        )

    # Optional lower-resolution proxy for later inference — keep fps from source.
    proxy_path: str | None = None
    # Milestone 1: skip heavy proxy generation for tiny clips; leave null.

    metadata: dict[str, Any] = {
        "job_id": job_id,
        "video_id": video_id,
        "engine_version": settings.engine_version,
        "duration_ms": validated.duration_ms,
        "fps": validated.fps,
        "width": validated.width,
        "height": validated.height,
        "frame_count": validated.frame_count,
        "codec": validated.codec,
        "mime_type": validated.mime_type,
        "rotation": validated.rotation,
        "file_size_bytes": validated.file_size_bytes,
        "original_path": str(validated.path),
        "normalized_path": normalized_path,
        "proxy_path": proxy_path,
        "quality_flags": validated.quality_flags,
        "view": view_hint,
        "quality_score": _quality_score(validated),
        "ffprobe_summary": {
            "format_name": (validated.raw_ffprobe.get("format") or {}).get("format_name"),
            "bit_rate": (validated.raw_ffprobe.get("format") or {}).get("bit_rate"),
        },
    }

    metadata_path = root / "metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True), encoding="utf-8")

    results_stub = {
        "job_id": job_id,
        "status": "metadata_ready",
        "note": "Milestone 1: validation and metadata only. No pose or coaching report.",
        "metadata": metadata,
    }
    (root / "results" / "m1_results.json").write_text(
        json.dumps(results_stub, indent=2, sort_keys=True),
        encoding="utf-8",
    )

    return PreprocessResult(
        original_path=str(validated.path),
        normalized_path=normalized_path,
        proxy_path=proxy_path,
        metadata_path=str(metadata_path.resolve()),
        metadata=metadata,
        limitations=limitations,
    )


def _quality_score(validated: ValidatedVideo) -> float:
    score = 1.0
    if validated.width < 720 or validated.height < 480:
        score -= 0.15
    if validated.fps < 24:
        score -= 0.1
    if validated.quality_flags:
        score -= 0.05 * len(validated.quality_flags)
    return max(0.0, min(1.0, round(score, 3)))


def metadata_as_dict(result: PreprocessResult) -> dict[str, Any]:
    return asdict(result)

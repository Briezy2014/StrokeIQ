"""Build recruiting highlight clip packs + auto-stitched reels via FFmpeg."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from app.config import Settings


class HighlightReelError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


# Recruiting-friendly stitch order (sales narrative: start → race → wall).
_TAG_ORDER = {
    "best start": 10,
    "underwaters": 20,
    "best turn": 30,
    "best finish": 40,
    "sprint finish": 50,
    "race": 60,
}

# Default windows as fractions of total duration when timestamps are omitted.
_TAG_FRACTIONS: dict[str, tuple[float, float]] = {
    "best start": (0.0, 0.14),
    "underwaters": (0.0, 0.18),
    "best turn": (0.42, 0.58),
    "best finish": (0.82, 1.0),
    "sprint finish": (0.86, 1.0),
    "race": (0.0, 0.22),  # opening race energy, not the full heat
}


@dataclass
class ResolvedClip:
    label: str
    tag: str
    start_ms: int
    end_ms: int
    source_path: Path
    output_path: Path
    file_name: str


def probe_duration_ms(ffprobe_path: str, video_path: Path) -> int:
    cmd = [
        ffprobe_path,
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "json",
        str(video_path),
    ]
    try:
        completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        raise HighlightReelError(
            "FFMPEG_UNAVAILABLE",
            f"ffprobe not found at '{ffprobe_path}'",
        ) from exc
    if completed.returncode != 0:
        err = (completed.stderr or completed.stdout or "ffprobe failed").strip()
        raise HighlightReelError("INVALID_VIDEO", f"Could not read video duration: {err}")
    try:
        data = json.loads(completed.stdout or "{}")
        duration_s = float(data.get("format", {}).get("duration") or 0)
    except (TypeError, ValueError, json.JSONDecodeError) as exc:
        raise HighlightReelError("INVALID_VIDEO", "Video duration missing") from exc
    if duration_s <= 0:
        raise HighlightReelError("INVALID_VIDEO", "Video duration is zero")
    return int(duration_s * 1000)


def resolve_window(
    *,
    tag: str,
    duration_ms: int,
    start_ms: int | None,
    end_ms: int | None,
    max_clip_ms: int,
) -> tuple[int, int]:
    tag_key = tag.strip().lower()
    if start_ms is not None and end_ms is not None and end_ms > start_ms:
        start = max(0, start_ms)
        end = min(duration_ms, end_ms)
    else:
        frac = _TAG_FRACTIONS.get(tag_key, (0.0, 0.15))
        start = int(duration_ms * frac[0])
        end = int(duration_ms * frac[1])

    if end <= start:
        end = min(duration_ms, start + min(3000, max_clip_ms))
    if end - start > max_clip_ms:
        # Keep the most relevant edge: finishes keep the end; others keep the start.
        if "finish" in tag_key:
            start = max(0, end - max_clip_ms)
        else:
            end = start + max_clip_ms
    if end > duration_ms:
        end = duration_ms
        start = max(0, end - min(max_clip_ms, duration_ms))
    if end <= start:
        raise HighlightReelError(
            "INVALID_SEGMENT",
            f"Could not resolve a usable window for tag '{tag}'",
        )
    return start, end


def _slug(text: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "-", text.strip().lower()).strip("-")
    return cleaned[:48] or "clip"


def trim_clip(
    *,
    ffmpeg_path: str,
    source: Path,
    dest: Path,
    start_ms: int,
    end_ms: int,
) -> None:
    start_s = start_ms / 1000.0
    duration_s = max(0.2, (end_ms - start_ms) / 1000.0)
    cmd = [
        ffmpeg_path,
        "-y",
        "-ss",
        f"{start_s:.3f}",
        "-i",
        str(source),
        "-t",
        f"{duration_s:.3f}",
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "23",
        "-pix_fmt",
        "yuv420p",
        "-an",
        "-movflags",
        "+faststart",
        str(dest),
    ]
    try:
        completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        raise HighlightReelError(
            "FFMPEG_UNAVAILABLE",
            f"ffmpeg not found at '{ffmpeg_path}'",
        ) from exc
    if completed.returncode != 0 or not dest.exists() or dest.stat().st_size < 100:
        err = (completed.stderr or completed.stdout or "ffmpeg trim failed").strip()
        raise HighlightReelError("REEL_BUILD_FAILED", f"Clip trim failed: {err[-400:]}")


def concat_clips(
    *,
    ffmpeg_path: str,
    clip_paths: list[Path],
    dest: Path,
    work_dir: Path,
) -> None:
    if not clip_paths:
        raise HighlightReelError("INVALID_SEGMENT", "No clips to stitch")
    list_path = work_dir / "concat.txt"
    # Re-encode concat for mismatched sources; use concat demuxer with intermediate
    # already-normalized H.264 clips from trim_clip.
    lines = []
    for path in clip_paths:
        escaped = str(path).replace("'", "'\\''")
        lines.append(f"file '{escaped}'")
    list_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    cmd = [
        ffmpeg_path,
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(list_path),
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "23",
        "-pix_fmt",
        "yuv420p",
        "-an",
        "-movflags",
        "+faststart",
        str(dest),
    ]
    try:
        completed = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        raise HighlightReelError(
            "FFMPEG_UNAVAILABLE",
            f"ffmpeg not found at '{ffmpeg_path}'",
        ) from exc
    if completed.returncode != 0 or not dest.exists() or dest.stat().st_size < 100:
        err = (completed.stderr or completed.stdout or "ffmpeg concat failed").strip()
        raise HighlightReelError("REEL_BUILD_FAILED", f"Reel stitch failed: {err[-400:]}")


def sort_segments(segments: list[dict[str, Any]]) -> list[dict[str, Any]]:
    def key(seg: dict[str, Any]) -> tuple[int, str]:
        tag = str(seg.get("tag") or "").strip().lower()
        return (_TAG_ORDER.get(tag, 100), str(seg.get("label") or ""))

    return sorted(segments, key=key)


def build_highlight_reel(
    *,
    settings: Settings,
    segments: list[dict[str, Any]],
    source_resolver,
    max_clip_ms: int = 6000,
    title: str = "Recruiting Highlight Reel",
) -> dict[str, Any]:
    """
    source_resolver(seg) -> Path to a local video file for that segment.
    """
    if not segments:
        raise HighlightReelError("INVALID_SEGMENT", "Add at least one tagged moment")

    reel_id = str(uuid.uuid4())
    work_dir = settings.artifact_root / "highlight_reels" / reel_id
    if work_dir.exists():
        shutil.rmtree(work_dir, ignore_errors=True)
    clips_dir = work_dir / "clips"
    clips_dir.mkdir(parents=True, exist_ok=True)

    ordered = sort_segments(segments)
    resolved: list[ResolvedClip] = []
    source_cache: dict[str, Path] = {}

    for index, seg in enumerate(ordered, start=1):
        tag = str(seg.get("tag") or "Race").strip()
        label = str(seg.get("label") or tag).strip()
        cache_key = (
            str(seg.get("local_path") or "")
            or f"{seg.get('storage_bucket')}:{seg.get('storage_path')}"
        )
        if cache_key in source_cache:
            source = source_cache[cache_key]
        else:
            source = source_resolver(seg)
            source_cache[cache_key] = source

        duration_ms = probe_duration_ms(settings.ffprobe_path, source)
        start_ms, end_ms = resolve_window(
            tag=tag,
            duration_ms=duration_ms,
            start_ms=seg.get("start_ms"),
            end_ms=seg.get("end_ms"),
            max_clip_ms=max_clip_ms,
        )
        file_name = f"{index:02d}-{_slug(tag)}-{_slug(label)}.mp4"
        out_path = clips_dir / file_name
        trim_clip(
            ffmpeg_path=settings.ffmpeg_path,
            source=source,
            dest=out_path,
            start_ms=start_ms,
            end_ms=end_ms,
        )
        resolved.append(
            ResolvedClip(
                label=label,
                tag=tag,
                start_ms=start_ms,
                end_ms=end_ms,
                source_path=source,
                output_path=out_path,
                file_name=file_name,
            )
        )

    reel_name = f"{_slug(title) or 'recruiting-highlight-reel'}.mp4"
    reel_path = work_dir / reel_name
    concat_clips(
        ffmpeg_path=settings.ffmpeg_path,
        clip_paths=[c.output_path for c in resolved],
        dest=reel_path,
        work_dir=work_dir,
    )

    manifest = {
        "reel_id": reel_id,
        "title": title,
        "reel_file": reel_name,
        "clips": [
            {
                "label": c.label,
                "tag": c.tag,
                "start_ms": c.start_ms,
                "end_ms": c.end_ms,
                "file_name": c.file_name,
            }
            for c in resolved
        ],
    }
    (work_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )

    return {
        "reel_id": reel_id,
        "title": title,
        "work_dir": work_dir,
        "reel_path": reel_path,
        "reel_file": reel_name,
        "clips": resolved,
        "manifest": manifest,
    }

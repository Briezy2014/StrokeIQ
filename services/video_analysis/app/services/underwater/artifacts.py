"""Diagnostic artifacts for underwater / breakout analysis."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np

from app.services.underwater.detector import UnderwaterDetectionResult
from app.services.underwater.signals import UnderwaterSignals
from app.services.underwater.types import MetricValue, UnderwaterEvent


def write_underwater_artifacts(
    output_dir: Path,
    *,
    job_id: str,
    video_id: str,
    signals: UnderwaterSignals,
    detection: UnderwaterDetectionResult,
    metrics: list[MetricValue],
    events: list[UnderwaterEvent],
    evidence_frame_images: list[Path] | None = None,
) -> dict[str, str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, str] = {}

    events_path = output_dir / "underwater_events.json"
    events_path.write_text(
        json.dumps(
            {
                "job_id": job_id,
                "video_id": video_id,
                "method": detection.method,
                "view_mode": detection.view_mode,
                "quality_flags": detection.quality_flags,
                "phase": detection.phase.to_dict() if detection.phase else None,
                "kick_frames": detection.kick_frames,
                "water_entry_frame": detection.water_entry_frame,
                "underwater_start_frame": detection.underwater_start_frame,
                "breakout_frame": detection.breakout_frame,
                "first_surface_stroke_frame": detection.first_surface_stroke_frame,
                "underwater_end_frame": detection.underwater_end_frame,
                "events": [e.to_dict() for e in events],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    paths["underwater_events_json"] = str(events_path.resolve())

    metrics_path = output_dir / "underwater_metrics.json"
    metrics_path.write_text(
        json.dumps({"job_id": job_id, "metrics": [m.to_dict() for m in metrics]}, indent=2),
        encoding="utf-8",
    )
    paths["underwater_metrics_json"] = str(metrics_path.resolve())

    series = {
        "frame_numbers": signals.frame_numbers.tolist(),
        "timestamps_ms": signals.timestamps_ms.tolist(),
        "ankle_y": _tolist(signals.ankle_y),
        "hip_y": _tolist(signals.hip_y),
        "knee_y": _tolist(signals.knee_y),
        "wrist_activity": _tolist(signals.wrist_activity),
        "kick_signal": _tolist(detection.ankle_kick_signal),
        "kick_frames": detection.kick_frames,
        "breakout_frame": detection.breakout_frame,
    }
    series_path = output_dir / "underwater_signal_series.json"
    series_path.write_text(json.dumps(series, indent=2), encoding="utf-8")
    paths["underwater_signal_series_json"] = str(series_path.resolve())

    charts = output_dir / "charts"
    charts.mkdir(parents=True, exist_ok=True)
    paths.update(_charts(charts, signals, detection))

    evidence_dir = output_dir / "evidence_frames"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    # Metadata listing for selected evidence frames (images optional)
    evidence_meta = {
        "breakout_frame": detection.breakout_frame,
        "kick_frames": detection.kick_frames[:8],
        "underwater_start_frame": detection.underwater_start_frame,
        "first_surface_stroke_frame": detection.first_surface_stroke_frame,
        "image_paths": [str(p) for p in (evidence_frame_images or [])],
    }
    evid_path = evidence_dir / "evidence_frames.json"
    evid_path.write_text(json.dumps(evidence_meta, indent=2), encoding="utf-8")
    paths["evidence_frames_json"] = str(evid_path.resolve())
    paths["evidence_frames_dir"] = str(evidence_dir.resolve())

    # Dedicated breakout marker file
    if detection.breakout_frame is not None:
        bo = output_dir / "detected_breakout_frame.json"
        bo.write_text(
            json.dumps(
                {
                    "frame_number": detection.breakout_frame,
                    "events": [e.to_dict() for e in events if e.event_type == "breakout"],
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        paths["detected_breakout_frame_json"] = str(bo.resolve())

    return paths


def _tolist(arr: np.ndarray) -> list[Any]:
    out = []
    for v in np.asarray(arr).tolist():
        if isinstance(v, float) and (np.isnan(v) or np.isinf(v)):
            out.append(None)
        else:
            out.append(v)
    return out


def _charts(
    charts_dir: Path,
    signals: UnderwaterSignals,
    detection: UnderwaterDetectionResult,
) -> dict[str, str]:
    paths: dict[str, str] = {}
    t = signals.timestamps_s
    if len(t) == 0:
        return paths

    fig, ax = plt.subplots(figsize=(10, 3.5))
    ax.plot(t, signals.ankle_y, color="#1f77b4", label="ankle_y")
    for fr in detection.kick_frames:
        idx = np.where(signals.frame_numbers == fr)[0]
        if idx.size:
            ax.axvline(t[int(idx[0])], color="#d62728", alpha=0.45, linestyle="--")
    ax.set_title("Ankle trajectory and kick peaks")
    ax.set_xlabel("time (s)")
    ax.legend(fontsize=8)
    fig.tight_layout()
    p = charts_dir / "ankle_trajectory.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_ankle_trajectory"] = str(p.resolve())

    fig, ax = plt.subplots(figsize=(10, 3.5))
    ax.plot(t, signals.hip_y, color="#ff7f0e", label="hip_y")
    if detection.underwater_start_frame is not None:
        idx = np.where(signals.frame_numbers == detection.underwater_start_frame)[0]
        if idx.size:
            ax.axvline(t[int(idx[0])], color="#2ca02c", linestyle=":", label="uw_start")
    if detection.breakout_frame is not None:
        idx = np.where(signals.frame_numbers == detection.breakout_frame)[0]
        if idx.size:
            ax.axvline(t[int(idx[0])], color="#d62728", linestyle="--", label="breakout")
    ax.set_title("Hip trajectory")
    ax.set_xlabel("time (s)")
    ax.legend(fontsize=8)
    fig.tight_layout()
    p = charts_dir / "hip_trajectory.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_hip_trajectory"] = str(p.resolve())

    fig, ax = plt.subplots(figsize=(10, 3.5))
    if len(detection.ankle_kick_signal) == len(t):
        ax.plot(t, detection.ankle_kick_signal, color="#9467bd", label="kick_energy")
    for fr in detection.kick_frames:
        idx = np.where(signals.frame_numbers == fr)[0]
        if idx.size:
            ax.scatter([t[int(idx[0])]], [detection.ankle_kick_signal[int(idx[0])]], color="#d62728", zorder=5)
    ax.set_title("Kick peaks")
    ax.set_xlabel("time (s)")
    ax.legend(fontsize=8)
    fig.tight_layout()
    p = charts_dir / "kick_peaks.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_kick_peaks"] = str(p.resolve())

    return paths

"""Butterfly analysis evidence artifacts and charts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np

from app.services.butterfly.cycle_detector import CycleDetectionResult
from app.services.butterfly.signals import ButterflySignals
from app.services.butterfly.types import MetricValue, StrokeEvent


def write_butterfly_artifacts(
    output_dir: Path,
    *,
    job_id: str,
    video_id: str,
    signals: ButterflySignals,
    detection: CycleDetectionResult,
    metrics: list[MetricValue],
    events: list[StrokeEvent],
) -> dict[str, str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, str] = {}

    cycles_path = output_dir / "cycle_boundaries.json"
    cycles_path.write_text(
        json.dumps(
            {
                "job_id": job_id,
                "video_id": video_id,
                "method": detection.method,
                "entry_frames": detection.entry_frames,
                "breath_frames": detection.breath_frames,
                "quality_flags": detection.quality_flags,
                "view_suitability": detection.view_suitability,
                "cycles": [c.to_dict() for c in detection.cycles],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    paths["cycle_boundaries_json"] = str(cycles_path.resolve())

    events_path = output_dir / "stroke_events.json"
    events_path.write_text(
        json.dumps({"job_id": job_id, "events": [e.to_dict() for e in events]}, indent=2),
        encoding="utf-8",
    )
    paths["stroke_events_json"] = str(events_path.resolve())

    metrics_path = output_dir / "butterfly_metrics.json"
    metrics_path.write_text(
        json.dumps({"job_id": job_id, "metrics": [m.to_dict() for m in metrics]}, indent=2),
        encoding="utf-8",
    )
    paths["butterfly_metrics_json"] = str(metrics_path.resolve())

    series = {
        "frame_numbers": signals.frame_numbers.tolist(),
        "timestamps_ms": signals.timestamps_ms.tolist(),
        "left_wrist_forward": _tolist(signals.left_wrist_forward),
        "right_wrist_forward": _tolist(signals.right_wrist_forward),
        "wrist_forward": _tolist(signals.wrist_forward),
        "entry_signal": _tolist(detection.entry_signal),
        "bilateral_sync": _tolist(signals.bilateral_sync),
        "head_elevation": _tolist(signals.head_elevation),
        "cycle_durations_s": [c.duration_s for c in detection.cycles if c.complete],
        "entry_frames": detection.entry_frames,
        "breath_frames": detection.breath_frames,
    }
    series_path = output_dir / "butterfly_signal_series.json"
    series_path.write_text(json.dumps(series, indent=2), encoding="utf-8")
    paths["butterfly_signal_series_json"] = str(series_path.resolve())

    charts_dir = output_dir / "charts"
    charts_dir.mkdir(parents=True, exist_ok=True)
    paths.update(
        _write_charts(
            charts_dir,
            signals=signals,
            detection=detection,
            events=events,
        )
    )
    return paths


def _tolist(arr: np.ndarray) -> list[Any]:
    out = []
    for v in arr.tolist():
        if v is None or (isinstance(v, float) and (np.isnan(v) or np.isinf(v))):
            out.append(None)
        else:
            out.append(v)
    return out


def _write_charts(
    charts_dir: Path,
    *,
    signals: ButterflySignals,
    detection: CycleDetectionResult,
    events: list[StrokeEvent],
) -> dict[str, str]:
    paths: dict[str, str] = {}
    t = signals.timestamps_s
    if len(t) == 0:
        return paths

    # Wrist trajectories + cycle boundaries
    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(t, signals.left_wrist_forward, label="left_wrist_forward", color="#1f77b4")
    ax.plot(t, signals.right_wrist_forward, label="right_wrist_forward", color="#ff7f0e")
    if len(detection.entry_signal) == len(t):
        ax.plot(t, detection.entry_signal, label="entry_signal", color="#2ca02c", alpha=0.8)
    for fr in detection.entry_frames:
        idx = np.where(signals.frame_numbers == fr)[0]
        if idx.size:
            ax.axvline(t[int(idx[0])], color="#d62728", alpha=0.5, linestyle="--")
    ax.set_xlabel("time (s)")
    ax.set_ylabel("forward projection (px)")
    ax.set_title("Wrist trajectories and cycle boundaries")
    ax.legend(loc="best", fontsize=8)
    fig.tight_layout()
    p = charts_dir / "wrist_trajectories_cycles.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_wrist_trajectories"] = str(p.resolve())

    # Cycle durations
    durs = [c.duration_s for c in detection.cycles if c.complete]
    fig, ax = plt.subplots(figsize=(8, 3.5))
    if durs:
        ax.bar(range(len(durs)), durs, color="#4c78a8")
        ax.axhline(float(np.mean(durs)), color="#e45756", linestyle="--", label="mean")
        ax.legend()
    ax.set_xlabel("cycle index")
    ax.set_ylabel("duration (s)")
    ax.set_title("Cycle durations")
    fig.tight_layout()
    p = charts_dir / "cycle_durations.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_cycle_durations"] = str(p.resolve())

    # Stroke-rate consistency (instantaneous)
    fig, ax = plt.subplots(figsize=(8, 3.5))
    if durs:
        rates = [60.0 / d for d in durs]
        ax.plot(range(len(rates)), rates, marker="o", color="#54a24b")
        ax.axhline(float(np.mean(rates)), color="#e45756", linestyle="--", label="mean rate")
        ax.legend()
    ax.set_xlabel("cycle index")
    ax.set_ylabel("cycles/min")
    ax.set_title("Stroke-rate consistency")
    fig.tight_layout()
    p = charts_dir / "stroke_rate_consistency.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_stroke_rate_consistency"] = str(p.resolve())

    # Breathing-event timing
    fig, ax = plt.subplots(figsize=(10, 3.5))
    ax.plot(t, signals.head_elevation, color="#b279a2", label="head_elevation")
    for e in events:
        if e.event_type == "breath_estimate":
            ax.axvline(e.timestamp_ms / 1000.0, color="#ff9da6", alpha=0.7)
    ax.set_xlabel("time (s)")
    ax.set_ylabel("elevation (px)")
    ax.set_title("Breathing-event timing")
    ax.legend(loc="best", fontsize=8)
    fig.tight_layout()
    p = charts_dir / "breathing_event_timing.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_breathing_event_timing"] = str(p.resolve())

    # Left/right entry timing
    fig, ax = plt.subplots(figsize=(10, 3.5))
    ax.plot(t, signals.left_wrist_forward, label="left", color="#1f77b4")
    ax.plot(t, signals.right_wrist_forward, label="right", color="#ff7f0e")
    for c in detection.cycles:
        for fr, color in ((c.left_entry_frame, "#1f77b4"), (c.right_entry_frame, "#ff7f0e")):
            if fr is None:
                continue
            idx = np.where(signals.frame_numbers == fr)[0]
            if idx.size:
                ax.axvline(t[int(idx[0])], color=color, alpha=0.4, linestyle=":")
    ax.set_title("Left/right entry timing")
    ax.set_xlabel("time (s)")
    ax.legend(loc="best", fontsize=8)
    fig.tight_layout()
    p = charts_dir / "left_right_entry_timing.png"
    fig.savefig(p, dpi=120)
    plt.close(fig)
    paths["chart_left_right_entry_timing"] = str(p.resolve())

    return paths

"""Diagnostic artifacts for turn / finish analysis."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np

from app.services.turn_finish.types import MetricValue, RaceEvent, WallCalibration


def write_turn_artifacts(
    output_dir: Path,
    *,
    job_id: str,
    video_id: str,
    kind: str,  # turn | finish
    calibration: WallCalibration,
    events: list[RaceEvent],
    metrics: list[MetricValue],
    series: dict[str, Any],
    image_bgr: Any | None = None,
) -> dict[str, str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, str] = {}

    cal_path = output_dir / "wall_calibration.json"
    cal_path.write_text(json.dumps(calibration.to_dict(), indent=2), encoding="utf-8")
    paths["wall_calibration_json"] = str(cal_path.resolve())

    # Wall-calibration frame image (optional still)
    if image_bgr is not None and calibration.wall_x is not None:
        try:
            import cv2

            img = image_bgr.copy()
            x = int(round(calibration.wall_x))
            cv2.line(img, (x, 0), (x, img.shape[0] - 1), (0, 255, 255), 2)
            cv2.putText(
                img,
                f"wall {calibration.method} conf={calibration.confidence:.2f}",
                (max(8, x - 120), 28),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (0, 255, 255),
                2,
            )
            cal_img = output_dir / "wall_calibration_frame.jpg"
            cv2.imwrite(str(cal_img), img)
            paths["wall_calibration_frame"] = str(cal_img.resolve())
        except Exception:  # noqa: BLE001
            pass
    else:
        # Placeholder calibration diagram from series
        fig, ax = plt.subplots(figsize=(8, 3))
        ax.plot(series["timestamps_ms"] / 1000.0, series["hip_x"], label="hip_x")
        if calibration.wall_x is not None:
            ax.axhline(calibration.wall_x, color="red", linestyle="--", label="wall_x")
        ax.set_title(f"Wall calibration ({calibration.method})")
        ax.legend(fontsize=8)
        fig.tight_layout()
        cal_img = output_dir / "wall_calibration_frame.png"
        fig.savefig(cal_img, dpi=120)
        plt.close(fig)
        paths["wall_calibration_frame"] = str(cal_img.resolve())

    events_path = output_dir / f"{kind}_events.json"
    events_path.write_text(
        json.dumps(
            {
                "job_id": job_id,
                "video_id": video_id,
                "kind": kind,
                "calibration": calibration.to_dict(),
                "events": [e.to_dict() for e in events],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    paths[f"{kind}_events_json"] = str(events_path.resolve())

    metrics_path = output_dir / f"{kind}_metrics.json"
    metrics_path.write_text(
        json.dumps({"job_id": job_id, "metrics": [m.to_dict() for m in metrics]}, indent=2),
        encoding="utf-8",
    )
    paths[f"{kind}_metrics_json"] = str(metrics_path.resolve())

    conf_path = output_dir / f"{kind}_confidence_report.json"
    conf_path.write_text(
        json.dumps(
            {
                "job_id": job_id,
                "calibration_confidence": calibration.confidence,
                "calibration_method": calibration.method,
                "event_confidences": {
                    e.event_type: {
                        "confidence": e.confidence,
                        "confidence_label": e.confidence_label,
                        "unavailable_reason": e.unavailable_reason,
                    }
                    for e in events
                },
                "metric_confidences": {
                    m.name: {
                        "confidence": m.confidence,
                        "confidence_label": m.confidence_label,
                        "unavailable_reason": m.unavailable_reason,
                    }
                    for m in metrics
                },
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    paths[f"{kind}_confidence_report"] = str(conf_path.resolve())

    # Timeline chart
    fig, ax = plt.subplots(figsize=(10, 3.5))
    ax.plot(series["timestamps_ms"] / 1000.0, series["dist_to_wall"], label="dist_to_wall", color="#1f77b4")
    for e in events:
        if e.timestamp_ms is not None:
            ax.axvline(e.timestamp_ms / 1000.0, alpha=0.4, linestyle="--")
            ax.text(e.timestamp_ms / 1000.0, ax.get_ylim()[1] if ax.get_ylim()[1] != 0 else 1, e.event_type, rotation=90, fontsize=7, va="top")
    ax.set_title(f"{kind.capitalize()} timeline")
    ax.set_xlabel("time (s)")
    ax.legend(fontsize=8)
    fig.tight_layout()
    tl = output_dir / f"{kind}_timeline.png"
    fig.savefig(tl, dpi=120)
    plt.close(fig)
    paths[f"{kind}_timeline"] = str(tl.resolve())

    # Evidence frames metadata
    evid_dir = output_dir / "evidence_frames"
    evid_dir.mkdir(parents=True, exist_ok=True)
    evidence = {
        "frames": sorted(
            {
                e.frame_number
                for e in events
                if e.frame_number is not None
            }
        ),
        "by_event": {
            e.event_type: e.frame_number for e in events if e.frame_number is not None
        },
    }
    evid_path = evid_dir / "evidence_frames.json"
    evid_path.write_text(json.dumps(evidence, indent=2), encoding="utf-8")
    paths["evidence_frames_json"] = str(evid_path.resolve())
    paths["evidence_frames_dir"] = str(evid_dir.resolve())

    return paths

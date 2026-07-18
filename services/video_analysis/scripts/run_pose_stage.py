#!/usr/bin/env python3
"""
Run exactly one Milestone 3 pose stage (A, B, or C).

Stages do NOT auto-advance. Stage B requires Stage A acceptance;
Stage C requires Stage B acceptance.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.config import Settings  # noqa: E402
from app.models.rtmdet_adapter import RTMDetOnnxAdapter  # noqa: E402
from app.services.pose_pipeline import PoseStageError, run_pose_stage  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", choices=["A", "B", "C"], required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--video-id", default="pose-stage")
    parser.add_argument("--job-id", default=None)
    parser.add_argument("--artifact-root", type=Path, default=ROOT / "analysis_artifacts")
    args = parser.parse_args()

    settings = Settings(
        artifact_root=args.artifact_root,
        job_store_path=args.artifact_root / "jobs.json",
        pose_enabled=True,
        pose_stage=args.stage,
        pose_device="cpu",
        min_width=160,
        min_height=120,
        min_fps=10,
        min_duration_ms=50,
        max_target_lost_frames=200,
        frame_processing_interval=4,
        min_detection_confidence=0.25,
        min_keypoint_confidence=0.05,
        min_visible_core_joints=4,
        detector_model_path=ROOT / "models" / "rtmdet-n-person.onnx",
        pose_config_path=ROOT
        / "models/rtmpose/rtmpose-m_8xb64-270e_coco-wholebody-256x192.py",
        pose_checkpoint_path=ROOT
        / "models/rtmpose/rtmpose-m_simcc-coco-wholebody_pt-aic-coco_270e-256x192-cd5e845c_20230123.pth",
    )
    settings.ensure_dirs()

    detector = None
    det_path = Path(settings.detector_model_path)
    if det_path.is_file():
        detector = RTMDetOnnxAdapter(det_path)

    job_id = args.job_id or f"pose-{args.stage.lower()}-{uuid4().hex[:8]}"
    try:
        result = run_pose_stage(
            settings=settings,
            stage=args.stage,
            job_id=job_id,
            video_id=args.video_id,
            source_path=args.source.resolve(),
            detector=detector,
            write_acceptance=True,
        )
    except PoseStageError as exc:
        print(json.dumps({"ok": False, "error_code": exc.error_code, "message": exc.message}))
        return 2

    print(
        json.dumps(
            {
                "ok": True,
                "stage": result.stage,
                "status": result.status,
                "average_inference_ms": result.average_inference_ms,
                "artifact_paths": result.artifact_paths,
                "acceptance_path": result.acceptance_path,
                "model_versions": result.model_versions,
                "usable_pose_records": sum(1 for p in result.poses if p.get("usable")),
                "unusable_frames": len(result.unusable_frames),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

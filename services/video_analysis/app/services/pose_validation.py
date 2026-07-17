"""Milestone 4 orchestration: validate/smooth poses and emit diagnostic artifacts."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from app.config import Settings
from app.services.pose_overlay import (
    export_diagnostic_frames,
    render_skeleton_overlay,
    write_frame_confidence_data,
    write_pose_quality_report,
    write_smoothed_pose_json,
)
from app.services.pose_smoother import SmoothPoseResult, SmoothingParams, smooth_pose_sequence
from app.services.tracking_diagnostics import write_json
from app.utils.logging import get_logger

logger = get_logger("video_analysis.pose_validation")


@dataclass
class PoseValidationResult:
    raw_poses: list[dict[str, Any]]
    smoothed_poses: list[dict[str, Any]]
    coverage: dict[str, Any]
    filter_method: str
    params: dict[str, Any]
    artifact_paths: dict[str, str]
    limitations: list[str]


def smoothing_params_from_settings(settings: Settings) -> SmoothingParams:
    return SmoothingParams(
        min_keypoint_confidence=settings.min_keypoint_confidence,
        max_interpolation_gap_frames=settings.max_interpolation_gap_frames,
        max_joint_velocity_px_s=settings.max_joint_velocity_px_s,
        max_joint_acceleration_px_s2=settings.max_joint_acceleration_px_s2,
        continuity_max_jump_px=settings.continuity_max_jump_px,
        savgol_window=settings.savgol_window,
        savgol_polyorder=settings.savgol_polyorder,
        long_occlusion_gap_frames=settings.long_occlusion_gap_frames,
        usable_frame_min_core_joints=settings.usable_frame_min_core_joints,
        usable_frame_min_confidence=settings.usable_frame_min_confidence,
    )


def run_pose_validation(
    *,
    settings: Settings,
    job_id: str,
    video_id: str,
    raw_poses: list[dict[str, Any]],
    output_root: Path,
    video_path: Path | None = None,
    tracked_frame_numbers: set[int] | None = None,
    params: SmoothingParams | None = None,
) -> PoseValidationResult:
    """
    Preserve raw poses, produce smoothed dataset + quality/diagnostic artifacts.

    Does not mutate the input raw_poses list contents in-place; works on a deep copy.
    """
    output_root.mkdir(parents=True, exist_ok=True)
    params = params or smoothing_params_from_settings(settings)

    # Snapshot raw before smoothing to prove immutability of Milestone 3 output.
    raw_snapshot = json.loads(json.dumps(raw_poses))

    result: SmoothPoseResult = smooth_pose_sequence(
        raw_poses,
        params=params,
        tracked_frame_numbers=tracked_frame_numbers,
    )

    if result.raw_poses != raw_snapshot:
        raise RuntimeError("Raw pose data was mutated during smoothing")
    # Caller must not observe in-place mutation of the input list either.
    if raw_poses != raw_snapshot:
        raise RuntimeError("Input raw pose list was mutated during smoothing")

    raw_path = output_root / "raw_pose.json"
    if not raw_path.is_file():
        write_json(
            raw_path,
            {
                "job_id": job_id,
                "video_id": video_id,
                "dataset": "raw",
                "poses": result.raw_poses,
            },
        )

    smoothed_path = output_root / "smoothed_pose.json"
    write_smoothed_pose_json(
        smoothed_path,
        job_id=job_id,
        video_id=video_id,
        smoothed_poses=result.smoothed_poses,
        filter_method=result.filter_method,
        coverage=result.coverage,
    )

    quality_path = output_root / "pose_quality_report.json"
    write_pose_quality_report(
        quality_path,
        job_id=job_id,
        coverage=result.coverage,
        params=params,
        filter_method=result.filter_method,
        limitations=result.limitations,
    )

    conf_path = output_root / "frame_confidence.json"
    write_frame_confidence_data(conf_path, result.frame_confidence)

    artifacts: dict[str, str] = {
        "raw_pose_json": str(raw_path.resolve()),
        "smoothed_pose_json": str(smoothed_path.resolve()),
        "pose_quality_report": str(quality_path.resolve()),
        "frame_confidence_json": str(conf_path.resolve()),
    }

    limitations = list(result.limitations)
    if video_path is not None and video_path.is_file() and _is_video(video_path):
        overlay_path = output_root / "skeleton_overlay.mp4"
        render_skeleton_overlay(
            video_path,
            result.smoothed_poses,
            overlay_path,
            job_id=job_id,
            min_draw_confidence=settings.overlay_min_draw_confidence,
        )
        artifacts["skeleton_overlay_video"] = str(overlay_path.resolve())

        diag_dir = output_root / "diagnostic_frames"
        diag_paths = export_diagnostic_frames(
            video_path,
            result.smoothed_poses,
            diag_dir,
            job_id=job_id,
            max_frames=settings.diagnostic_frame_count,
            min_draw_confidence=settings.overlay_min_draw_confidence,
        )
        artifacts["diagnostic_frames_dir"] = str(diag_dir.resolve())
        artifacts["diagnostic_frame_count"] = str(len(diag_paths))
    else:
        limitations.append("Skeleton overlay skipped (no video source)")

    logger.info(
        "Pose validation complete job=%s coverage=%.1f usable=%.1f",
        job_id,
        result.coverage.pose_coverage_percentage,
        result.coverage.usable_frame_percentage,
    )

    return PoseValidationResult(
        raw_poses=result.raw_poses,
        smoothed_poses=result.smoothed_poses,
        coverage=result.coverage.to_dict(),
        filter_method=result.filter_method,
        params=result.params,
        artifact_paths=artifacts,
        limitations=limitations,
    )


def _is_video(path: Path) -> bool:
    return path.suffix.lower() in {".mp4", ".mov", ".avi", ".mkv", ".webm"}

"""Analysis pipeline: validate → preprocess → detect/track (Milestone 2)."""

from __future__ import annotations

from pathlib import Path

from app.api.schemas.responses import JobStatus
from app.config import Settings
from app.domain.jobs import AnalysisJob
from app.models.detector_adapter import DetectorAdapter
from app.services.result_store import ResultStore
from app.services.pose_pipeline import PoseStageError, run_pose_stage
from app.services.swimmer_detector import DetectionError, run_detection_and_tracking
from app.services.video_preprocessor import artifact_dir, preprocess_video
from app.services.video_validator import VideoValidationError, validate_video
from app.utils.logging import get_logger, log_exception, log_stage

logger = get_logger("video_analysis.pipeline")


def resolve_local_path(job: AnalysisJob) -> Path:
    if job.local_path:
        return Path(job.local_path).expanduser().resolve()
    raise VideoValidationError(
        "LOCAL_PATH_REQUIRED",
        "Milestone 1/2 requires local_path. Supabase download lands in a later milestone.",
        retriable=False,
    )


def run_analysis_pipeline(
    job: AnalysisJob,
    *,
    settings: Settings,
    store: ResultStore,
    detector: DetectorAdapter | None = None,
    skip_detection: bool = False,
) -> AnalysisJob:
    """Full M1+M2 pipeline. `skip_detection` retained for pure M1 unit tests."""
    video_id = job.video_id
    job_id = job.job_id

    if job.cancelled:
        job.mark_failed(
            error_code="CANCELLED",
            message="Job was cancelled before processing started",
            stage=JobStatus.queued.value,
            retriable=False,
        )
        store.save(job)
        return job

    try:
        job.transition(JobStatus.validating, progress=0.08)
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Starting video validation",
        )

        path = resolve_local_path(job)
        validated = validate_video(path, settings)

        if job.cancelled:
            job.mark_failed(
                error_code="CANCELLED",
                message="Job was cancelled during validation",
                stage=JobStatus.validating.value,
                retriable=False,
            )
            store.save(job)
            return job

        job.transition(JobStatus.preprocessing, progress=0.25)
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Validation passed; writing metadata artifacts",
        )

        options = (job.request_payload or {}).get("options") or {}
        view_hint = options.get("view_hint") or "unknown"
        result = preprocess_video(
            settings=settings,
            job_id=job_id,
            video_id=video_id,
            validated=validated,
            view_hint=view_hint,
        )

        job.metadata = result.metadata
        job.metadata_artifact_path = result.metadata_path
        job.limitations = list(result.limitations)

        video_for_detection = Path(result.normalized_path or result.original_path)

        if skip_detection:
            if job.limitations:
                job.transition(JobStatus.completed_with_limitations, progress=1.0)
            else:
                job.transition(JobStatus.completed, progress=1.0)
            job.error = None
            store.save(job)
            return job

        if job.cancelled:
            job.mark_failed(
                error_code="CANCELLED",
                message="Job was cancelled before detection",
                stage=JobStatus.preprocessing.value,
                retriable=False,
            )
            store.save(job)
            return job

        job.transition(JobStatus.detecting_swimmer, progress=0.45)
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Starting swimmer detection and tracking",
        )

        art = artifact_dir(settings, job_id)
        tracking = run_detection_and_tracking(
            settings=settings,
            job_id=job_id,
            video_id=video_id,
            video_path=video_for_detection,
            artifact_root=art,
            options=options,
            detector=detector,
        )

        job.tracking = {
            "target": tracking.target,
            "quality_summary": tracking.quality_summary,
            "artifact_paths": tracking.artifact_paths,
            "config": tracking.config_versions,
            "track_count": len(tracking.tracks),
            "detection_count": len(tracking.detections),
        }
        job.model_versions = tracking.model_versions
        job.limitations = list(dict.fromkeys([*job.limitations, *tracking.limitations]))

        # Milestone 3: optional single pose stage (A/B/C). Never auto-advances stages.
        if settings.pose_enabled or bool(options.get("run_pose_stage")):
            stage = str(options.get("pose_stage") or settings.pose_stage or "A").upper()
            if stage not in {"A", "B", "C"}:
                raise PoseStageError("INVALID_POSE_STAGE", f"Invalid pose stage {stage}")
            job.transition(JobStatus.estimating_pose, progress=0.75)
            store.save(job)
            pose_source = Path(
                options.get("pose_source_path") or video_for_detection
            )
            pose_result = run_pose_stage(
                settings=settings,
                stage=stage,  # type: ignore[arg-type]
                job_id=job_id,
                video_id=video_id,
                source_path=pose_source,
                output_root=art / "pose" / f"stage_{stage}",
                detector=detector,
                write_acceptance=bool(options.get("write_pose_acceptance", True)),
            )
            job.pose = {
                "stage": pose_result.stage,
                "status": pose_result.status,
                "artifact_paths": pose_result.artifact_paths,
                "average_inference_ms": pose_result.average_inference_ms,
                "unusable_frames": pose_result.unusable_frames,
                "acceptance_path": pose_result.acceptance_path,
                "pose_count": len(pose_result.poses),
            }
            job.model_versions.update(pose_result.model_versions)
            job.limitations = list(
                dict.fromkeys([*job.limitations, *pose_result.limitations])
            )

        if tracking.completed_with_limitations or job.limitations:
            job.transition(JobStatus.completed_with_limitations, progress=1.0)
        else:
            job.transition(JobStatus.completed, progress=1.0)
        job.error = None
        store.save(job)
        log_stage(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            message="Pipeline completed through configured milestone stages",
            target_track_id=tracking.target.get("track_id"),
            annotated=tracking.artifact_paths.get("annotated_tracking_video"),
            pose_stage=(job.pose or {}).get("stage"),
        )
        return job

    except PoseStageError as exc:
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code=exc.error_code,
            message=exc.message,
            stage=job.stage,
            retriable=False,
        )
        store.save(job)
        return job

    except VideoValidationError as exc:
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code=exc.error_code,
            message=exc.message,
            stage=job.stage,
            retriable=exc.retriable,
        )
        store.save(job)
        return job
    except DetectionError as exc:
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code=exc.error_code,
            message=exc.message,
            stage=job.stage if job.stage else JobStatus.detecting_swimmer.value,
            retriable=exc.retriable,
        )
        store.save(job)
        return job
    except Exception as exc:  # noqa: BLE001
        log_exception(
            logger,
            stage=job.stage,
            job_id=job_id,
            video_id=video_id,
            error=exc,
        )
        job.mark_failed(
            error_code="INTERNAL_ERROR",
            message=str(exc),
            stage=job.stage,
            retriable=True,
        )
        store.save(job)
        return job


# Backwards-compatible alias used by older tests/imports
def run_milestone1_pipeline(
    job: AnalysisJob,
    *,
    settings: Settings,
    store: ResultStore,
) -> AnalysisJob:
    return run_analysis_pipeline(
        job, settings=settings, store=store, skip_detection=True
    )

"""Analysis pipeline: validate → preprocess → detect/track (Milestone 2)."""

from __future__ import annotations

from pathlib import Path

from app.api.schemas.responses import JobStatus
from app.config import Settings
from app.domain.jobs import AnalysisJob
from app.models.detector_adapter import DetectorAdapter
from app.services.result_store import ResultStore
from app.services.butterfly.analyzer import ButterflyAnalyzer
from app.services.pose_pipeline import PoseStageError, run_pose_stage
from app.services.report import ReportGenerator
from app.services.report.artifacts import result_to_job_payload
from app.services.turn_finish import FinishAnalyzer, TurnAnalyzer
from app.services.underwater.analyzer import UnderwaterAnalyzer
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
            summary_path = pose_result.artifact_paths.get("pose_stage_summary")
            coverage = {}
            if summary_path:
                import json
                from pathlib import Path as _Path

                try:
                    coverage = json.loads(_Path(summary_path).read_text(encoding="utf-8")).get(
                        "pose_coverage"
                    ) or {}
                except Exception:  # noqa: BLE001
                    coverage = {}
            job.pose = {
                "stage": pose_result.stage,
                "status": pose_result.status,
                "artifact_paths": pose_result.artifact_paths,
                "average_inference_ms": pose_result.average_inference_ms,
                "unusable_frames": pose_result.unusable_frames,
                "acceptance_path": pose_result.acceptance_path,
                "pose_count": len(pose_result.poses),
                "pose_coverage": coverage,
            }
            job.model_versions.update(pose_result.model_versions)
            job.limitations = list(
                dict.fromkeys([*job.limitations, *pose_result.limitations])
            )

            # Milestone 5: butterfly surface analysis on smoothed poses only.
            run_bfly = settings.butterfly_analysis_enabled or bool(
                options.get("run_butterfly_analysis")
            )
            stroke_hint = str(
                ((job.request_payload or {}).get("event") or {}).get("stroke") or "unknown"
            )
            if run_bfly:
                smoothed_path = pose_result.artifact_paths.get("smoothed_pose_json")
                if not smoothed_path:
                    job.limitations.append("butterfly_analysis_skipped_no_smoothed_poses")
                else:
                    job.transition(JobStatus.detecting_events, progress=0.85)
                    store.save(job)
                    view_hint = str(options.get("view_hint") or "unknown")
                    analyzer = ButterflyAnalyzer(settings=settings)
                    bfly = analyzer.analyze_from_smoothed_json(
                        Path(smoothed_path),
                        job_id=job_id,
                        video_id=video_id,
                        output_dir=art / "butterfly",
                        stroke_hint=stroke_hint,
                        view_hint=view_hint,
                        pool_distance_calibrated=bool(
                            options.get("pool_distance_calibrated")
                            or settings.pool_distance_calibrated
                        ),
                    )
                    job.transition(JobStatus.calculating_metrics, progress=0.92)
                    store.save(job)
                    job.butterfly = {
                        "summary": bfly.summary,
                        "artifact_paths": bfly.artifact_paths,
                        "entry_frames": bfly.entry_frames,
                        "breath_frames": bfly.breath_frames,
                        "detection_method": bfly.detection_method,
                        "quality_flags": bfly.quality_flags,
                        "metrics": bfly.metrics,
                        "events": bfly.events,
                        "cycles": bfly.cycles,
                    }
                    job.model_versions["milestone"] = "5"
                    job.model_versions["butterfly"] = "surface_v1"
                    job.limitations = list(
                        dict.fromkeys([*job.limitations, *bfly.limitations])
                    )

            # Milestone 6: underwater / dolphin-kick / breakout (uses smoothed poses + optional M5 entries).
            run_uw = settings.underwater_analysis_enabled or bool(
                options.get("run_underwater_analysis")
            )
            if run_uw:
                smoothed_path = (job.pose or {}).get("artifact_paths", {}).get(
                    "smoothed_pose_json"
                ) or pose_result.artifact_paths.get("smoothed_pose_json")
                if not smoothed_path:
                    job.limitations.append("underwater_analysis_skipped_no_smoothed_poses")
                else:
                    # Advance through event/metric stages only when not already there (M5 may have).
                    if job.status == JobStatus.estimating_pose:
                        job.transition(JobStatus.detecting_events, progress=0.86)
                        store.save(job)
                    view_hint = str(options.get("view_hint") or "unknown")
                    surface_entries = list((job.butterfly or {}).get("entry_frames") or [])
                    track_obs = []
                    if job.tracking and job.tracking.get("target"):
                        track_obs = list(
                            ((job.tracking.get("target") or {}).get("observations")) or []
                        )
                    uw_analyzer = UnderwaterAnalyzer(settings=settings)
                    uw = uw_analyzer.analyze_from_smoothed_json(
                        Path(smoothed_path),
                        job_id=job_id,
                        video_id=video_id,
                        output_dir=art / "underwater",
                        view_hint=view_hint,
                        pool_distance_calibrated=bool(
                            options.get("pool_distance_calibrated")
                            or settings.pool_distance_calibrated
                        ),
                        surface_stroke_entry_frames=surface_entries or None,
                        track_observations=track_obs or None,
                    )
                    if job.status == JobStatus.detecting_events:
                        job.transition(JobStatus.calculating_metrics, progress=0.94)
                        store.save(job)
                    elif job.status == JobStatus.calculating_metrics:
                        job.progress = max(job.progress, 0.94)
                        store.save(job)
                    job.underwater = {
                        "summary": uw.summary,
                        "artifact_paths": uw.artifact_paths,
                        "kick_frames": uw.kick_frames,
                        "breakout_frame": uw.breakout_frame,
                        "first_surface_stroke_frame": uw.first_surface_stroke_frame,
                        "detection_method": uw.detection_method,
                        "quality_flags": uw.quality_flags,
                        "metrics": uw.metrics,
                        "events": uw.events,
                        "phase": uw.phase,
                    }
                    job.model_versions["milestone"] = "6"
                    job.model_versions["underwater"] = "phase_v1"
                    job.limitations = list(
                        dict.fromkeys([*job.limitations, *uw.limitations])
                    )

            # Milestone 7: turn / finish event framework (unavailable when view unsupported).
            run_turn = settings.turn_analysis_enabled or bool(options.get("run_turn_analysis"))
            run_finish = settings.finish_analysis_enabled or bool(
                options.get("run_finish_analysis")
            )
            if run_turn or run_finish:
                smoothed_path = (job.pose or {}).get("artifact_paths", {}).get(
                    "smoothed_pose_json"
                ) or pose_result.artifact_paths.get("smoothed_pose_json")
                if not smoothed_path:
                    job.limitations.append("turn_finish_skipped_no_smoothed_poses")
                else:
                    if job.status == JobStatus.estimating_pose:
                        job.transition(JobStatus.detecting_events, progress=0.88)
                        store.save(job)
                    import json as _json

                    poses = _json.loads(Path(smoothed_path).read_text(encoding="utf-8")).get(
                        "poses"
                    ) or []
                    view_hint = str(options.get("view_hint") or "unknown")
                    stroke_hint = str(
                        ((job.request_payload or {}).get("event") or {}).get("stroke")
                        or "unknown"
                    )
                    surface_entries = list((job.butterfly or {}).get("entry_frames") or [])
                    uw_kicks = list((job.underwater or {}).get("kick_frames") or [])
                    uw_breakout = (job.underwater or {}).get("breakout_frame")
                    wall_kwargs = {
                        "manual_wall_line": options.get("manual_wall_line"),
                        "pool_geometry": options.get("pool_geometry"),
                        "lane_line_termination_x": options.get("lane_line_termination_x"),
                        "starting_block_x": options.get("starting_block_x"),
                    }
                    if run_turn:
                        turn_result = TurnAnalyzer(settings=settings).analyze(
                            poses,
                            job_id=job_id,
                            video_id=video_id,
                            output_dir=art / "turn",
                            view_hint=view_hint,
                            stroke_hint=stroke_hint,
                            turn_type_hint=options.get("turn_type_hint"),
                            surface_stroke_entry_frames=surface_entries or None,
                            underwater_kick_frames=uw_kicks or None,
                            breakout_frame=uw_breakout,
                            **wall_kwargs,
                        )
                        job.turn = {
                            "summary": turn_result.summary,
                            "artifact_paths": turn_result.artifact_paths,
                            "calibration": turn_result.calibration,
                            "events": turn_result.events,
                            "metrics": turn_result.metrics,
                            "quality_flags": turn_result.quality_flags,
                            "view_supported": turn_result.view_supported,
                        }
                        job.limitations = list(
                            dict.fromkeys([*job.limitations, *turn_result.limitations])
                        )
                    if run_finish:
                        finish_result = FinishAnalyzer(settings=settings).analyze(
                            poses,
                            job_id=job_id,
                            video_id=video_id,
                            output_dir=art / "finish",
                            view_hint=view_hint,
                            stroke_hint=stroke_hint,
                            surface_stroke_entry_frames=surface_entries or None,
                            **wall_kwargs,
                        )
                        job.finish = {
                            "summary": finish_result.summary,
                            "artifact_paths": finish_result.artifact_paths,
                            "calibration": finish_result.calibration,
                            "events": finish_result.events,
                            "metrics": finish_result.metrics,
                            "quality_flags": finish_result.quality_flags,
                            "view_supported": finish_result.view_supported,
                        }
                        job.limitations = list(
                            dict.fromkeys([*job.limitations, *finish_result.limitations])
                        )
                    if job.status == JobStatus.detecting_events:
                        job.transition(JobStatus.calculating_metrics, progress=0.96)
                        store.save(job)
                    elif job.status == JobStatus.calculating_metrics:
                        job.progress = max(job.progress, 0.96)
                        store.save(job)
                    job.model_versions["milestone"] = "7"
                    job.model_versions["turn_finish"] = "framework_v1"

        # Milestone 8: coaching report from structured CV results only (never raw video).
        # Deterministic metrics remain on the job even when Gemini fails.
        run_report = settings.gemini_report_enabled or bool(
            options.get("generate_gemini_report")
        )
        if run_report:
            if job.status != JobStatus.generating_report:
                job.transition(JobStatus.generating_report, progress=0.98)
                store.save(job)
            report_opts = options.get("report_options") or {}
            report_result = ReportGenerator(settings=settings).generate_for_job(
                job,
                output_dir=art / "report",
                authorize_age_group=bool(report_opts.get("authorize_age_group")),
                authorize_previous_results=bool(
                    report_opts.get("authorize_previous_results")
                ),
                previous_athlete_results=report_opts.get("previous_athlete_results"),
                approved_standards=report_opts.get("approved_standards"),
                evidence_frame_paths=report_opts.get("evidence_frame_paths"),
                attach_evidence_images=bool(
                    settings.gemini_attach_evidence_images
                    or report_opts.get("attach_evidence_images")
                ),
            )
            job.report = result_to_job_payload(report_result)
            job.limitations = list(
                dict.fromkeys([*job.limitations, *report_result.limitations])
            )
            job.model_versions["milestone"] = "8"
            job.model_versions["gemini_report"] = (
                (report_result.report.model_name if report_result.report else None)
                or settings.gemini_model_name
            )
            if report_result.report:
                job.model_versions["gemini_prompt_version"] = (
                    report_result.report.prompt_version
                )
                job.model_versions["gemini_report_schema"] = (
                    report_result.report.schema_version
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
            butterfly_cycles=((job.butterfly or {}).get("summary") or {}).get(
                "complete_cycles"
            ),
            underwater_kicks=((job.underwater or {}).get("summary") or {}).get(
                "kick_count"
            ),
            gemini_report=bool((job.report or {}).get("gemini_succeeded")),
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

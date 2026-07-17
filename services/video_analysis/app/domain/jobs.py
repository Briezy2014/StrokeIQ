"""In-process job model and allowed state transitions."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from app.api.schemas.responses import JobError, JobStatus


ALLOWED_TRANSITIONS: dict[JobStatus, set[JobStatus]] = {
    JobStatus.queued: {JobStatus.validating, JobStatus.failed},
    JobStatus.validating: {
        JobStatus.preprocessing,
        JobStatus.failed,
        JobStatus.completed_with_limitations,
    },
    JobStatus.preprocessing: {
        JobStatus.detecting_swimmer,
        JobStatus.completed,  # M1-only path if detection skipped (not used in M2 default)
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    },
    JobStatus.detecting_swimmer: {
        JobStatus.estimating_pose,
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    },
    JobStatus.estimating_pose: {
        JobStatus.completed,
        JobStatus.completed_with_limitations,
        JobStatus.failed,
    },
    JobStatus.failed: {JobStatus.queued, JobStatus.validating},
    JobStatus.completed: set(),
    JobStatus.completed_with_limitations: set(),
}


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def new_job_id() -> str:
    return str(uuid4())


class AnalysisJob:
    def __init__(
        self,
        *,
        job_id: str,
        video_id: str,
        engine_version: str,
        request_payload: dict[str, Any],
        local_path: str | None = None,
        storage_bucket: str | None = None,
        storage_path: str | None = None,
    ) -> None:
        now = utc_now()
        self.job_id = job_id
        self.video_id = video_id
        self.engine_version = engine_version
        self.status = JobStatus.queued
        self.stage = JobStatus.queued.value
        self.progress = 0.0
        self.retry_count = 0
        self.error: JobError | None = None
        self.request_payload = request_payload
        self.local_path = local_path
        self.storage_bucket = storage_bucket
        self.storage_path = storage_path
        self.metadata: dict[str, Any] | None = None
        self.limitations: list[str] = []
        self.metadata_artifact_path: str | None = None
        self.tracking: dict[str, Any] | None = None
        self.pose: dict[str, Any] | None = None
        self.model_versions: dict[str, str] = {}
        self.created_at = now
        self.updated_at = now
        self.cancelled = False

    def transition(self, new_status: JobStatus, *, progress: float | None = None) -> None:
        allowed = ALLOWED_TRANSITIONS.get(self.status, set())
        if new_status not in allowed and new_status != self.status:
            raise ValueError(
                f"Illegal transition {self.status.value} -> {new_status.value}"
            )
        self.status = new_status
        self.stage = new_status.value
        if progress is not None:
            self.progress = max(0.0, min(1.0, progress))
        self.updated_at = utc_now()

    def mark_failed(
        self,
        *,
        error_code: str,
        message: str,
        stage: str,
        retriable: bool,
    ) -> None:
        self.status = JobStatus.failed
        self.stage = stage
        self.progress = 1.0
        self.error = JobError(
            error_code=error_code,
            message=message,
            stage=stage,
            job_id=self.job_id,
            retriable=retriable,
        )
        self.updated_at = utc_now()

    def to_dict(self) -> dict[str, Any]:
        return {
            "job_id": self.job_id,
            "video_id": self.video_id,
            "engine_version": self.engine_version,
            "status": self.status.value,
            "stage": self.stage,
            "progress": self.progress,
            "retry_count": self.retry_count,
            "error": self.error.model_dump() if self.error else None,
            "request_payload": self.request_payload,
            "local_path": self.local_path,
            "storage_bucket": self.storage_bucket,
            "storage_path": self.storage_path,
            "metadata": self.metadata,
            "limitations": self.limitations,
            "metadata_artifact_path": self.metadata_artifact_path,
            "tracking": self.tracking,
            "pose": self.pose,
            "model_versions": self.model_versions,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "cancelled": self.cancelled,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> AnalysisJob:
        job = cls(
            job_id=data["job_id"],
            video_id=data["video_id"],
            engine_version=data["engine_version"],
            request_payload=data.get("request_payload") or {},
            local_path=data.get("local_path"),
            storage_bucket=data.get("storage_bucket"),
            storage_path=data.get("storage_path"),
        )
        job.status = JobStatus(data["status"])
        job.stage = data.get("stage", job.status.value)
        job.progress = float(data.get("progress", 0.0))
        job.retry_count = int(data.get("retry_count", 0))
        if data.get("error"):
            job.error = JobError(**data["error"])
        job.metadata = data.get("metadata")
        job.limitations = list(data.get("limitations") or [])
        job.metadata_artifact_path = data.get("metadata_artifact_path")
        job.tracking = data.get("tracking")
        job.pose = data.get("pose")
        job.model_versions = dict(data.get("model_versions") or {})
        job.created_at = datetime.fromisoformat(data["created_at"])
        job.updated_at = datetime.fromisoformat(data["updated_at"])
        job.cancelled = bool(data.get("cancelled", False))
        return job

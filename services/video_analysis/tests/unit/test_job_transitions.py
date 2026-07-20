import pytest

from app.api.schemas.responses import JobStatus
from app.domain.jobs import AnalysisJob


def test_legal_m2_transitions():
    job = AnalysisJob(
        job_id="j1",
        video_id="v1",
        engine_version="elote-0.2.0",
        request_payload={},
    )
    job.transition(JobStatus.downloading, progress=0.05)
    job.transition(JobStatus.downloading, progress=0.08)  # progress heartbeat
    job.transition(JobStatus.validating, progress=0.12)
    job.transition(JobStatus.preprocessing, progress=0.4)
    job.transition(JobStatus.detecting_swimmer, progress=0.7)
    job.transition(JobStatus.completed, progress=1.0)
    assert job.status == JobStatus.completed


def test_illegal_transition():
    job = AnalysisJob(
        job_id="j1",
        video_id="v1",
        engine_version="elote-0.1.0",
        request_payload={},
    )
    with pytest.raises(ValueError):
        job.transition(JobStatus.estimating_pose)


def test_queued_can_skip_download_to_validating():
    """Local-path jobs may go straight to validating without downloading."""
    job = AnalysisJob(
        job_id="j1",
        video_id="v1",
        engine_version="elote-0.8.0",
        request_payload={},
    )
    job.transition(JobStatus.validating, progress=0.12)
    assert job.status == JobStatus.validating


def test_generating_report_transition():
    job = AnalysisJob(
        job_id="j1",
        video_id="v1",
        engine_version="elote-0.8.0",
        request_payload={},
    )
    job.transition(JobStatus.validating, progress=0.1)
    job.transition(JobStatus.preprocessing, progress=0.2)
    job.transition(JobStatus.detecting_swimmer, progress=0.4)
    job.transition(JobStatus.generating_report, progress=0.98)
    job.transition(JobStatus.completed_with_limitations, progress=1.0)
    assert job.status == JobStatus.completed_with_limitations

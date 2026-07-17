import pytest

from app.api.schemas.responses import JobStatus
from app.domain.jobs import AnalysisJob


def test_legal_m1_transitions():
    job = AnalysisJob(
        job_id="j1",
        video_id="v1",
        engine_version="elote-0.1.0",
        request_payload={},
    )
    job.transition(JobStatus.validating, progress=0.2)
    job.transition(JobStatus.preprocessing, progress=0.6)
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

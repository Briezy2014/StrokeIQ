from pathlib import Path

from app.api.schemas.responses import JobStatus
from app.domain.jobs import AnalysisJob, new_job_id
from app.services.job_pipeline import run_milestone1_pipeline
from app.services.result_store import ResultStore


def test_pipeline_writes_metadata(settings, valid_video: Path):
    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="direct-1",
        engine_version=settings.engine_version,
        request_payload={"options": {"view_hint": "side"}},
        local_path=str(valid_video),
    )
    store.save(job)
    finished = run_milestone1_pipeline(job, settings=settings, store=store)
    assert finished.status in {JobStatus.completed, JobStatus.completed_with_limitations}
    assert finished.metadata is not None
    assert Path(finished.metadata_artifact_path).is_file()
    assert finished.metadata["original_path"]
    # Original preserved — preprocessor must not delete source
    assert Path(valid_video).is_file()


def test_pipeline_fails_corrupt(settings, corrupt_video: Path):
    store = ResultStore(settings.job_store_path)
    job = AnalysisJob(
        job_id=new_job_id(),
        video_id="direct-bad",
        engine_version=settings.engine_version,
        request_payload={},
        local_path=str(corrupt_video),
    )
    store.save(job)
    finished = run_milestone1_pipeline(job, settings=settings, store=store)
    assert finished.status == JobStatus.failed
    assert finished.error is not None
    assert finished.error.error_code

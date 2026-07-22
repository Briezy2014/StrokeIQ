"""Missing pose deps must soft-skip — never hard-fail Elite coaching."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest

from app.services.pose_pipeline import PoseStageError, run_pose_stage


def test_missing_pose_stack_raises_pose_stage_error(settings, tmp_path: Path):
    settings.pose_enabled = True
    source = tmp_path / "clip.mp4"
    source.write_bytes(b"not-a-real-video")

    with patch(
        "app.services.pose_pipeline.assert_pose_stack_ready",
        side_effect=RuntimeError(
            "Pose dependency stack not ready: missing=['torch'] "
            "errors=[\"torch: No module named 'torch'\"]"
        ),
    ):
        with pytest.raises(PoseStageError) as exc:
            run_pose_stage(
                settings=settings,
                stage="A",
                job_id="soft-1",
                video_id="vid-soft",
                source_path=source,
                output_root=tmp_path / "pose",
                write_acceptance=False,
            )

    assert exc.value.error_code == "POSE_DEPS_MISSING"
    assert "No module named" not in exc.value.message
    assert "phone coaching" in exc.value.message.lower()

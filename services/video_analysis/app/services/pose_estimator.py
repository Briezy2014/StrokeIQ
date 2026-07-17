"""PoseEstimator interface — RTMPose adapter lands in Milestone 3."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Protocol


class PoseFrame(Protocol):
    frame_number: int
    timestamp_ms: float


class PoseEstimator(ABC):
    """Replaceable pose backend. Milestone 1 does not instantiate a production estimator."""

    @abstractmethod
    def estimate(self, image_bgr: Any, *, frame_number: int, timestamp_ms: float) -> dict:
        raise NotImplementedError


class NotImplementedPoseEstimator(PoseEstimator):
    def estimate(self, image_bgr: Any, *, frame_number: int, timestamp_ms: float) -> dict:
        raise NotImplementedError("Pose estimation begins in Milestone 3 (RTMPose WholeBody).")

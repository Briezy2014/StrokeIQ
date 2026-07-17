"""PoseEstimator interface and shared pose result types (Milestone 3)."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass
class Keypoint:
    name: str
    x: float | None
    y: float | None
    z: float | None
    confidence: float
    x_crop: float | None = None
    y_crop: float | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "x": self.x,
            "y": self.y,
            "z": self.z,
            "confidence": self.confidence,
            "x_crop": self.x_crop,
            "y_crop": self.y_crop,
        }


@dataclass
class PoseEstimate:
    video_id: str
    job_id: str
    frame_number: int
    timestamp_ms: float
    swimmer_track_id: str | None
    crop_coordinates: list[float]  # [x1,y1,x2,y2] in original frame
    keypoints: list[Keypoint]
    overall_pose_confidence: float
    model_name: str
    model_version: str
    inference_resolution: list[int]
    processing_duration_ms: float
    usable: bool = True
    unusable_reason: str | None = None
    quality_flags: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "video_id": self.video_id,
            "job_id": self.job_id,
            "frame_number": self.frame_number,
            "timestamp_ms": self.timestamp_ms,
            "swimmer_track_id": self.swimmer_track_id,
            "crop_coordinates": self.crop_coordinates,
            "keypoints": [k.to_dict() for k in self.keypoints],
            "overall_pose_confidence": self.overall_pose_confidence,
            "model_name": self.model_name,
            "model_version": self.model_version,
            "inference_resolution": self.inference_resolution,
            "processing_duration_ms": self.processing_duration_ms,
            "usable": self.usable,
            "unusable_reason": self.unusable_reason,
            "quality_flags": self.quality_flags,
        }


class PoseEstimator(ABC):
    """Replaceable pose backend. Production primary: RTMPose WholeBody via MMPose."""

    @property
    @abstractmethod
    def model_name(self) -> str: ...

    @property
    @abstractmethod
    def model_version(self) -> str: ...

    @abstractmethod
    def is_loaded(self) -> bool: ...

    @abstractmethod
    def load(self) -> None:
        """Load model weights once; safe to call repeatedly."""

    @abstractmethod
    def estimate_crop(
        self,
        image_bgr: Any,
        *,
        crop_xyxy: list[float],
        video_id: str,
        job_id: str,
        frame_number: int,
        timestamp_ms: float,
        swimmer_track_id: str | None,
        min_keypoint_confidence: float,
        min_visible_core_joints: int,
    ) -> PoseEstimate:
        """Estimate pose for one person crop in an original-frame image."""


class PoseEstimatorError(Exception):
    def __init__(self, error_code: str, message: str, *, retriable: bool = False) -> None:
        super().__init__(message)
        self.error_code = error_code
        self.message = message
        self.retriable = retriable

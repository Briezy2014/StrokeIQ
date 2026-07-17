"""Replaceable person/swimmer detector interface (Milestone 2)."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass
class BoundingBox:
    x1: float
    y1: float
    x2: float
    y2: float

    @property
    def width(self) -> float:
        return max(0.0, self.x2 - self.x1)

    @property
    def height(self) -> float:
        return max(0.0, self.y2 - self.y1)

    @property
    def area(self) -> float:
        return self.width * self.height

    @property
    def cx(self) -> float:
        return (self.x1 + self.x2) / 2.0

    @property
    def cy(self) -> float:
        return (self.y1 + self.y2) / 2.0

    def iou(self, other: BoundingBox) -> float:
        ix1 = max(self.x1, other.x1)
        iy1 = max(self.y1, other.y1)
        ix2 = min(self.x2, other.x2)
        iy2 = min(self.y2, other.y2)
        iw = max(0.0, ix2 - ix1)
        ih = max(0.0, iy2 - iy1)
        inter = iw * ih
        union = self.area + other.area - inter
        if union <= 0:
            return 0.0
        return inter / union

    def clamp(self, width: int, height: int) -> BoundingBox:
        return BoundingBox(
            x1=float(max(0, min(width - 1, self.x1))),
            y1=float(max(0, min(height - 1, self.y1))),
            x2=float(max(0, min(width - 1, self.x2))),
            y2=float(max(0, min(height - 1, self.y2))),
        )

    def as_list(self) -> list[float]:
        return [self.x1, self.y1, self.x2, self.y2]


@dataclass
class Detection:
    frame_number: int
    timestamp_ms: float
    bbox: BoundingBox
    confidence: float
    temporary_detection_id: str
    model_name: str
    model_version: str
    label: str = "person"
    extras: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "frame_number": self.frame_number,
            "timestamp_ms": self.timestamp_ms,
            "bbox": self.bbox.as_list(),
            "detection_confidence": self.confidence,
            "temporary_detection_id": self.temporary_detection_id,
            "model_name": self.model_name,
            "model_version": self.model_version,
            "label": self.label,
            **self.extras,
        }


class DetectorAdapter(ABC):
    """Production detectors implement this interface (RTMDet primary)."""

    @property
    @abstractmethod
    def model_name(self) -> str: ...

    @property
    @abstractmethod
    def model_version(self) -> str: ...

    @abstractmethod
    def detect(
        self,
        image_bgr: Any,
        *,
        frame_number: int,
        timestamp_ms: float,
        min_confidence: float,
    ) -> list[Detection]:
        raise NotImplementedError

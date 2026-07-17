"""Scripted detector for deterministic unit/integration tests."""

from __future__ import annotations

from typing import Any, Callable

from app.models.detector_adapter import BoundingBox, Detection, DetectorAdapter

FrameScript = dict[int, list[tuple[list[float], float]]]
# frame_number -> list of ([x1,y1,x2,y2], confidence)


class ScriptedDetectorAdapter(DetectorAdapter):
    def __init__(
        self,
        script: FrameScript | None = None,
        *,
        model_name: str = "scripted-detector",
        model_version: str = "test-1.0",
        generator: Callable[[int, float, Any], list[Detection]] | None = None,
    ) -> None:
        self._script = script or {}
        self._generator = generator
        self._name = model_name
        self._version = model_version

    @property
    def model_name(self) -> str:
        return self._name

    @property
    def model_version(self) -> str:
        return self._version

    def detect(
        self,
        image_bgr: Any,
        *,
        frame_number: int,
        timestamp_ms: float,
        min_confidence: float,
    ) -> list[Detection]:
        if self._generator is not None:
            dets = self._generator(frame_number, timestamp_ms, image_bgr)
            return [d for d in dets if d.confidence >= min_confidence]

        out: list[Detection] = []
        for idx, (bbox, conf) in enumerate(self._script.get(frame_number, [])):
            if conf < min_confidence:
                continue
            out.append(
                Detection(
                    frame_number=frame_number,
                    timestamp_ms=timestamp_ms,
                    bbox=BoundingBox(*bbox),
                    confidence=conf,
                    temporary_detection_id=f"script-{frame_number}-{idx}",
                    model_name=self.model_name,
                    model_version=self.model_version,
                )
            )
        return out

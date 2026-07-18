"""RTMDet person detector via ONNX Runtime (Apache-2.0 RTMDet weights)."""

from __future__ import annotations

from pathlib import Path
from typing import Any
from uuid import uuid4

import cv2
import numpy as np
import onnxruntime as ort

from app.models.detector_adapter import BoundingBox, Detection, DetectorAdapter


class RTMDetOnnxAdapter(DetectorAdapter):
    """Primary production detector: RTMDet-n person ONNX (input 320x320 BGR)."""

    DEFAULT_MODEL_NAME = "rtmdet-n-person"
    DEFAULT_MODEL_VERSION = "onnx-1.0-openmmlab-rtmdet"

    def __init__(
        self,
        model_path: str | Path,
        *,
        input_size: int = 320,
        providers: list[str] | None = None,
    ) -> None:
        self._model_path = Path(model_path)
        if not self._model_path.is_file():
            raise FileNotFoundError(
                f"RTMDet ONNX model not found: {self._model_path}. "
                "Run scripts/download_rtmdet.py"
            )
        self._input_size = input_size
        session_options = ort.SessionOptions()
        session_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        # Keep CPU inference snappy on coach laptops without oversubscribing.
        try:
            session_options.intra_op_num_threads = 4
            session_options.inter_op_num_threads = 1
        except Exception:  # noqa: BLE001
            pass
        self._session = ort.InferenceSession(
            str(self._model_path),
            sess_options=session_options,
            providers=providers or ["CPUExecutionProvider"],
        )
        self._input_name = self._session.get_inputs()[0].name

    @property
    def model_name(self) -> str:
        return self.DEFAULT_MODEL_NAME

    @property
    def model_version(self) -> str:
        return f"{self.DEFAULT_MODEL_VERSION}:{self._model_path.name}"

    def detect(
        self,
        image_bgr: Any,
        *,
        frame_number: int,
        timestamp_ms: float,
        min_confidence: float,
    ) -> list[Detection]:
        if image_bgr is None or getattr(image_bgr, "size", 0) == 0:
            return []

        h, w = image_bgr.shape[:2]
        tensor, scale, pad_x, pad_y = self._preprocess(image_bgr)
        dets, labels = self._session.run(None, {self._input_name: tensor})
        boxes = dets[0]
        label_arr = labels[0]

        detections: list[Detection] = []
        for idx, row in enumerate(boxes):
            if row.shape[0] < 5:
                continue
            x1, y1, x2, y2, score = map(float, row[:5])
            if score < min_confidence:
                continue
            if x2 <= x1 or y2 <= y1:
                continue
            # Drop boxes clearly outside letterbox canvas.
            if x1 < -5 or y1 < -5 or x2 > self._input_size + 5 or y2 > self._input_size + 5:
                continue

            ox1 = (x1 - pad_x) / scale
            oy1 = (y1 - pad_y) / scale
            ox2 = (x2 - pad_x) / scale
            oy2 = (y2 - pad_y) / scale
            bbox = BoundingBox(ox1, oy1, ox2, oy2).clamp(w, h)
            if bbox.area <= 1:
                continue

            label_id = int(label_arr[idx]) if idx < len(label_arr) else 0
            detections.append(
                Detection(
                    frame_number=frame_number,
                    timestamp_ms=timestamp_ms,
                    bbox=bbox,
                    confidence=score,
                    temporary_detection_id=f"det-{frame_number}-{idx}-{uuid4().hex[:8]}",
                    model_name=self.model_name,
                    model_version=self.model_version,
                    label="person" if label_id == 0 else str(label_id),
                )
            )

        return self._nms(detections, iou_threshold=0.45)

    def _preprocess(
        self, image_bgr: np.ndarray
    ) -> tuple[np.ndarray, float, float, float]:
        h, w = image_bgr.shape[:2]
        scale = min(self._input_size / w, self._input_size / h)
        nw, nh = int(w * scale), int(h * scale)
        resized = cv2.resize(image_bgr, (nw, nh))
        canvas = np.full((self._input_size, self._input_size, 3), 114, dtype=np.uint8)
        pad_x = (self._input_size - nw) // 2
        pad_y = (self._input_size - nh) // 2
        canvas[pad_y : pad_y + nh, pad_x : pad_x + nw] = resized
        # Verified working preprocess for bukuroo RTMDet-n-person ONNX: BGR 0-255 NCHW
        tensor = canvas.astype(np.float32).transpose(2, 0, 1)[None]
        return tensor, scale, float(pad_x), float(pad_y)

    @staticmethod
    def _nms(detections: list[Detection], *, iou_threshold: float) -> list[Detection]:
        if not detections:
            return []
        ordered = sorted(detections, key=lambda d: d.confidence, reverse=True)
        kept: list[Detection] = []
        while ordered:
            best = ordered.pop(0)
            kept.append(best)
            ordered = [d for d in ordered if best.bbox.iou(d.bbox) < iou_threshold]
        return kept

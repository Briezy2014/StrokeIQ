"""Persistent multi-swimmer tracker (Milestone 2)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import numpy as np

from app.models.detector_adapter import BoundingBox, Detection


@dataclass
class TrackObservation:
    frame_number: int
    timestamp_ms: float
    bbox: list[float]
    detection_confidence: float
    temporary_detection_id: str
    flags: list[str] = field(default_factory=list)


@dataclass
class Track:
    track_id: str
    observations: list[TrackObservation] = field(default_factory=list)
    hits: int = 0
    misses: int = 0
    age: int = 0
    active: bool = True
    appearance: np.ndarray | None = None
    lane_index: int | None = None
    switch_risk_events: int = 0
    occlusion_events: int = 0
    left_frame_events: int = 0
    reenter_events: int = 0

    @property
    def last(self) -> TrackObservation | None:
        return self.observations[-1] if self.observations else None

    def last_bbox(self) -> BoundingBox | None:
        if not self.last:
            return None
        return BoundingBox(*self.last.bbox)

    def tracking_confidence(self) -> float:
        if not self.observations:
            return 0.0
        recent = self.observations[-min(10, len(self.observations)) :]
        mean_det = float(np.mean([o.detection_confidence for o in recent]))
        continuity = min(1.0, self.hits / max(1, self.age))
        miss_penalty = min(0.5, self.misses * 0.05)
        switch_penalty = min(0.4, self.switch_risk_events * 0.1)
        return float(max(0.0, min(1.0, 0.55 * mean_det + 0.45 * continuity - miss_penalty - switch_penalty)))

    def to_dict(self) -> dict[str, Any]:
        return {
            "track_id": self.track_id,
            "hits": self.hits,
            "misses": self.misses,
            "age": self.age,
            "active": self.active,
            "lane_index": self.lane_index,
            "tracking_confidence": self.tracking_confidence(),
            "switch_risk_events": self.switch_risk_events,
            "occlusion_events": self.occlusion_events,
            "left_frame_events": self.left_frame_events,
            "reenter_events": self.reenter_events,
            "observations": [
                {
                    "frame_number": o.frame_number,
                    "timestamp_ms": o.timestamp_ms,
                    "bbox": o.bbox,
                    "detection_confidence": o.detection_confidence,
                    "temporary_detection_id": o.temporary_detection_id,
                    "flags": o.flags,
                }
                for o in self.observations
            ],
        }


class SwimmerTracker:
    def __init__(
        self,
        *,
        max_lost_frames: int = 15,
        max_active_tracks: int = 12,
        iou_weight: float = 0.45,
        center_weight: float = 0.25,
        lane_weight: float = 0.15,
        trajectory_weight: float = 0.10,
        appearance_weight: float = 0.05,
        match_threshold: float = 0.35,
        lane_count: int = 8,
        frame_width: int = 1280,
        frame_height: int = 720,
    ) -> None:
        self.max_lost_frames = max_lost_frames
        self.max_active_tracks = max_active_tracks
        self.iou_weight = iou_weight
        self.center_weight = center_weight
        self.lane_weight = lane_weight
        self.trajectory_weight = trajectory_weight
        self.appearance_weight = appearance_weight
        self.match_threshold = match_threshold
        self.lane_count = lane_count
        self.frame_width = frame_width
        self.frame_height = frame_height
        self._next_id = 1
        self.tracks: list[Track] = []
        self.events: list[dict[str, Any]] = []

    def update(
        self,
        detections: list[Detection],
        *,
        frame_bgr: np.ndarray | None = None,
    ) -> list[Track]:
        active = [t for t in self.tracks if t.active]
        for t in active:
            t.age += 1

        if not active and not detections:
            return self.tracks

        cost = self._score_matrix(active, detections, frame_bgr)
        matches, unmatched_tracks, unmatched_dets = self._greedy_match(cost, active, detections)

        for ti, di in matches:
            track = active[ti]
            det = detections[di]
            flags: list[str] = []
            prev = track.last_bbox()
            if prev is not None and prev.iou(det.bbox) < 0.15:
                flags.append("track_switching_risk")
                track.switch_risk_events += 1
                self.events.append(
                    {
                        "type": "track_switching_risk",
                        "track_id": track.track_id,
                        "frame_number": det.frame_number,
                    }
                )
            if track.misses > 0:
                flags.append("reacquired_after_gap")
                if track.misses >= 3:
                    track.occlusion_events += 1
                    flags.append("temporary_occlusion")
                if any(e.get("type") == "swimmer_leaving_frame" and e.get("track_id") == track.track_id for e in self.events[-20:]):
                    track.reenter_events += 1
                    flags.append("reentered_frame")
                    self.events.append(
                        {
                            "type": "swimmer_reentering_frame",
                            "track_id": track.track_id,
                            "frame_number": det.frame_number,
                        }
                    )

            # Crossing risk if another track close
            for other in active:
                if other.track_id == track.track_id or not other.last:
                    continue
                if BoundingBox(*other.last.bbox).iou(det.bbox) > 0.2:
                    flags.append("multiple_swimmers_crossing")
                    self.events.append(
                        {
                            "type": "multiple_swimmers_crossing",
                            "track_ids": [track.track_id, other.track_id],
                            "frame_number": det.frame_number,
                        }
                    )
                    break

            track.observations.append(
                TrackObservation(
                    frame_number=det.frame_number,
                    timestamp_ms=det.timestamp_ms,
                    bbox=det.bbox.as_list(),
                    detection_confidence=det.confidence,
                    temporary_detection_id=det.temporary_detection_id,
                    flags=flags,
                )
            )
            track.hits += 1
            track.misses = 0
            track.lane_index = self._lane_index(det.bbox)
            if frame_bgr is not None:
                track.appearance = self._appearance(frame_bgr, det.bbox)

        for ti in unmatched_tracks:
            track = active[ti]
            track.misses += 1
            if track.last:
                bbox = BoundingBox(*track.last.bbox)
                near_edge = (
                    bbox.x1 < 8
                    or bbox.y1 < 8
                    or bbox.x2 > self.frame_width - 8
                    or bbox.y2 > self.frame_height - 8
                )
                if near_edge:
                    track.left_frame_events += 1
                    self.events.append(
                        {
                            "type": "swimmer_leaving_frame",
                            "track_id": track.track_id,
                            "frame_number": track.last.frame_number,
                        }
                    )
                else:
                    self.events.append(
                        {
                            "type": "temporary_occlusion",
                            "track_id": track.track_id,
                            "frame_number": track.last.frame_number + 1,
                        }
                    )
                    track.occlusion_events += 1
            if track.misses > self.max_lost_frames:
                track.active = False
                self.events.append(
                    {
                        "type": "lost_track",
                        "track_id": track.track_id,
                        "frame_number": track.last.frame_number if track.last else -1,
                        "misses": track.misses,
                    }
                )

        for di in unmatched_dets:
            if len([t for t in self.tracks if t.active]) >= self.max_active_tracks:
                continue
            det = detections[di]
            track_id = f"track-{self._next_id:04d}"
            self._next_id += 1
            track = Track(track_id=track_id)
            track.observations.append(
                TrackObservation(
                    frame_number=det.frame_number,
                    timestamp_ms=det.timestamp_ms,
                    bbox=det.bbox.as_list(),
                    detection_confidence=det.confidence,
                    temporary_detection_id=det.temporary_detection_id,
                )
            )
            track.hits = 1
            track.age = 1
            track.lane_index = self._lane_index(det.bbox)
            if frame_bgr is not None:
                track.appearance = self._appearance(frame_bgr, det.bbox)
            self.tracks.append(track)

        return self.tracks

    def _lane_index(self, bbox: BoundingBox) -> int:
        # Side-view proxy: vertical bands; deck/side view uses y; default use y center.
        ratio = bbox.cy / max(1.0, float(self.frame_height))
        idx = int(ratio * self.lane_count)
        return max(0, min(self.lane_count - 1, idx))

    def _appearance(self, frame_bgr: np.ndarray, bbox: BoundingBox) -> np.ndarray:
        x1, y1, x2, y2 = [int(v) for v in bbox.as_list()]
        crop = frame_bgr[max(0, y1) : max(0, y2), max(0, x1) : max(0, x2)]
        if crop.size == 0:
            return np.zeros(24, dtype=np.float32)
        hsv = __import__("cv2").cvtColor(crop, __import__("cv2").COLOR_BGR2HSV)
        hist = __import__("cv2").calcHist([hsv], [0, 1], None, [8, 3], [0, 180, 0, 256])
        hist = __import__("cv2").normalize(hist, hist).flatten().astype(np.float32)
        return hist

    def _appearance_score(self, track: Track, frame_bgr: np.ndarray | None, det: Detection) -> float:
        if track.appearance is None or frame_bgr is None:
            return 0.5
        other = self._appearance(frame_bgr, det.bbox)
        denom = float(np.linalg.norm(track.appearance) * np.linalg.norm(other))
        if denom <= 1e-8:
            return 0.0
        return float(max(0.0, min(1.0, np.dot(track.appearance, other) / denom)))

    def _trajectory_score(self, track: Track, det: Detection) -> float:
        if len(track.observations) < 2:
            return 0.5
        p0 = BoundingBox(*track.observations[-2].bbox)
        p1 = BoundingBox(*track.observations[-1].bbox)
        pred_cx = p1.cx + (p1.cx - p0.cx)
        pred_cy = p1.cy + (p1.cy - p0.cy)
        dist = np.hypot(det.bbox.cx - pred_cx, det.bbox.cy - pred_cy)
        diag = np.hypot(self.frame_width, self.frame_height)
        return float(max(0.0, 1.0 - dist / max(1.0, 0.25 * diag)))

    def _score_matrix(
        self,
        tracks: list[Track],
        detections: list[Detection],
        frame_bgr: np.ndarray | None,
    ) -> np.ndarray:
        if not tracks or not detections:
            return np.zeros((len(tracks), len(detections)), dtype=np.float32)
        scores = np.zeros((len(tracks), len(detections)), dtype=np.float32)
        diag = np.hypot(self.frame_width, self.frame_height)
        for i, track in enumerate(tracks):
            prev = track.last_bbox()
            if prev is None:
                continue
            for j, det in enumerate(detections):
                iou = prev.iou(det.bbox)
                center_dist = np.hypot(prev.cx - det.bbox.cx, prev.cy - det.bbox.cy)
                center_score = max(0.0, 1.0 - center_dist / max(1.0, 0.2 * diag))
                lane_score = 1.0 if track.lane_index == self._lane_index(det.bbox) else 0.25
                traj = self._trajectory_score(track, det)
                app = self._appearance_score(track, frame_bgr, det)
                scores[i, j] = (
                    self.iou_weight * iou
                    + self.center_weight * center_score
                    + self.lane_weight * lane_score
                    + self.trajectory_weight * traj
                    + self.appearance_weight * app
                )
        return scores

    def _greedy_match(
        self,
        scores: np.ndarray,
        tracks: list[Track],
        detections: list[Detection],
    ) -> tuple[list[tuple[int, int]], list[int], list[int]]:
        matches: list[tuple[int, int]] = []
        used_t: set[int] = set()
        used_d: set[int] = set()
        if scores.size:
            flat = [
                (float(scores[i, j]), i, j)
                for i in range(scores.shape[0])
                for j in range(scores.shape[1])
            ]
            flat.sort(reverse=True)
            for score, i, j in flat:
                if score < self.match_threshold:
                    break
                if i in used_t or j in used_d:
                    continue
                used_t.add(i)
                used_d.add(j)
                matches.append((i, j))
        unmatched_tracks = [i for i in range(len(tracks)) if i not in used_t]
        unmatched_dets = [j for j in range(len(detections)) if j not in used_d]
        return matches, unmatched_tracks, unmatched_dets

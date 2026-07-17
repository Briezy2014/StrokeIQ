"""Target swimmer selection modes (Milestone 2)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal

from app.models.detector_adapter import BoundingBox
from app.services.swimmer_tracker import Track

TargetMode = Literal["automatic", "track_id", "normalized_coordinate", "bounding_box"]


@dataclass
class TargetSelectionResult:
    mode: TargetMode
    track_id: str | None
    confidence: float
    uncertain: bool
    reason: str
    candidate_track_ids: list[str]
    flags: list[str]

    def to_dict(self) -> dict[str, Any]:
        return {
            "mode": self.mode,
            "track_id": self.track_id,
            "target_identity_confidence": self.confidence,
            "uncertain": self.uncertain,
            "reason": self.reason,
            "candidate_track_ids": self.candidate_track_ids,
            "flags": self.flags,
            # Future manual correction support
            "manual_selection_supported": True,
        }


def select_target(
    tracks: list[Track],
    *,
    mode: TargetMode = "automatic",
    track_id: str | None = None,
    normalized_xy: tuple[float, float] | None = None,
    bbox: list[float] | None = None,
    frame_width: int = 1280,
    frame_height: int = 720,
    min_confidence: float = 0.4,
) -> TargetSelectionResult:
    usable = [t for t in tracks if t.observations]
    candidates = sorted(usable, key=lambda t: (t.hits, t.tracking_confidence()), reverse=True)
    candidate_ids = [t.track_id for t in candidates]

    if not candidates:
        return TargetSelectionResult(
            mode=mode,
            track_id=None,
            confidence=0.0,
            uncertain=True,
            reason="No tracks available for target selection",
            candidate_track_ids=[],
            flags=["no_tracks", "low_confidence_target_identity"],
        )

    if mode == "track_id":
        if not track_id:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason="track_id mode requires options.target_track_id",
                candidate_track_ids=candidate_ids,
                flags=["missing_manual_track_id"],
            )
        match = next((t for t in candidates if t.track_id == track_id), None)
        if match is None:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason=f"Requested track_id {track_id} not found",
                candidate_track_ids=candidate_ids,
                flags=["track_id_not_found", "low_confidence_target_identity"],
            )
        conf = match.tracking_confidence()
        return TargetSelectionResult(
            mode=mode,
            track_id=match.track_id,
            confidence=conf,
            uncertain=conf < min_confidence,
            reason="Manual track_id selection",
            candidate_track_ids=candidate_ids,
            flags=[] if conf >= min_confidence else ["low_confidence_target_identity"],
        )

    if mode == "normalized_coordinate":
        if not normalized_xy:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason="normalized_coordinate mode requires options.target_normalized_xy",
                candidate_track_ids=candidate_ids,
                flags=["missing_normalized_coordinate"],
            )
        nx, ny = normalized_xy
        px, py = nx * frame_width, ny * frame_height
        best = None
        best_dist = float("inf")
        for track in candidates:
            last = track.last_bbox()
            if last is None:
                continue
            dist = ((last.cx - px) ** 2 + (last.cy - py) ** 2) ** 0.5
            if dist < best_dist:
                best_dist = dist
                best = track
        if best is None:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason="No track near normalized coordinate",
                candidate_track_ids=candidate_ids,
                flags=["low_confidence_target_identity"],
            )
        diag = (frame_width**2 + frame_height**2) ** 0.5
        proximity = max(0.0, 1.0 - best_dist / max(1.0, 0.2 * diag))
        conf = 0.5 * best.tracking_confidence() + 0.5 * proximity
        return TargetSelectionResult(
            mode=mode,
            track_id=best.track_id,
            confidence=conf,
            uncertain=conf < min_confidence,
            reason="Nearest track to normalized screen coordinate",
            candidate_track_ids=candidate_ids,
            flags=[] if conf >= min_confidence else ["low_confidence_target_identity"],
        )

    if mode == "bounding_box":
        if not bbox or len(bbox) != 4:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason="bounding_box mode requires options.target_bbox [x1,y1,x2,y2]",
                candidate_track_ids=candidate_ids,
                flags=["missing_target_bbox"],
            )
        user_box = BoundingBox(*bbox)
        best = None
        best_iou = -1.0
        for track in candidates:
            last = track.last_bbox()
            if last is None:
                continue
            iou = user_box.iou(last)
            if iou > best_iou:
                best_iou = iou
                best = track
        if best is None or best_iou <= 0:
            return TargetSelectionResult(
                mode=mode,
                track_id=None,
                confidence=0.0,
                uncertain=True,
                reason="No track overlaps user bounding box",
                candidate_track_ids=candidate_ids,
                flags=["low_confidence_target_identity"],
            )
        conf = 0.4 * best.tracking_confidence() + 0.6 * best_iou
        return TargetSelectionResult(
            mode=mode,
            track_id=best.track_id,
            confidence=conf,
            uncertain=conf < min_confidence,
            reason="Highest IoU with user-selected bounding box",
            candidate_track_ids=candidate_ids,
            flags=[] if conf >= min_confidence else ["low_confidence_target_identity"],
        )

    # automatic — DO NOT assume largest person alone.
    # Prefer continuity (hits), lane stability, tracking confidence; size is a weak tie-break only.
    scored: list[tuple[float, Track]] = []
    for track in candidates:
        size_score = 0.0
        if track.last:
            area = BoundingBox(*track.last.bbox).area
            size_score = min(1.0, area / max(1.0, 0.15 * frame_width * frame_height))
        score = (
            0.50 * track.tracking_confidence()
            + 0.30 * min(1.0, track.hits / 20.0)
            + 0.10 * (1.0 if track.active else 0.0)
            + 0.10 * size_score  # weak prior only
        )
        scored.append((score, track))
    scored.sort(key=lambda x: x[0], reverse=True)
    best_score, best = scored[0]
    uncertain = False
    flags: list[str] = []
    if len(scored) > 1 and abs(scored[0][0] - scored[1][0]) < 0.08:
        uncertain = True
        flags.append("ambiguous_multi_swimmer_target")
    if best_score < min_confidence:
        uncertain = True
        flags.append("low_confidence_target_identity")
    return TargetSelectionResult(
        mode="automatic",
        track_id=best.track_id,
        confidence=float(best_score),
        uncertain=uncertain,
        reason="Automatic selection from continuity, confidence, and weak size prior",
        candidate_track_ids=candidate_ids,
        flags=flags,
    )

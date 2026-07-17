"""Validate Gemini coaching reports against deterministic evidence (Milestone 8)."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.services.report.schemas import (
    CoachingObservation,
    CoachingReportBody,
    ReportContext,
)

MEDICAL_PATTERNS = re.compile(
    r"\b(injur(?:y|ies)|diagnos(?:e|is|ed)|concussion|fracture|surgery|pain\b|"
    r"medical|physio|therapy for|swollen|torn\b|strain\b|sprain)\b",
    re.I,
)
SHAME_PATTERNS = re.compile(
    r"\b(lazy|pathetic|hopeless|embarrassing|awful|terrible swimmer|bad kid|"
    r"you always fail|worthless|stupid|dumb)\b",
    re.I,
)
CHILD_COMPARE_PATTERNS = re.compile(
    r"\b(better than|worse than|behind|ahead of)\b.{0,40}\b(child|kid|classmate|teammate|other swimmer)\b|"
    r"\b(child|kid|classmate|teammate)\b.{0,40}\b(better|worse|faster|slower)\b",
    re.I,
)
CERTAINTY_PATTERNS = re.compile(
    r"\b(definitely|certainly|proves|proven|without (a )?doubt|always|"
    r"guaranteed|exactly\s+\d)\b",
    re.I,
)
MODERATE_CUES = re.compile(r"\b(the analysis suggests|suggests that|appears to|likely)\b", re.I)
LOW_CUES = re.compile(
    r"\b(the available frames may indicate|may indicate|might|possibly|could be)\b",
    re.I,
)
# Measurement-like number with unit or sports quantity wording nearby
MEASUREMENT_CLAIM = re.compile(
    r"(?P<num>\d+(?:\.\d+)?)\s*"
    r"(?P<unit>strokes?(?:/?min)?|kicks?|meters?|metres?|degrees|deg|seconds|sec|ms|%\b|m\b|s\b)",
    re.I,
)
BARE_STAT = re.compile(
    r"\b(?:stroke rate|tempo|duration|angle|distance|kick count|rate)\b[^.]{0,40}"
    r"(?P<num>\d+(?:\.\d+)?)",
    re.I,
)


@dataclass
class ValidationResult:
    ok: bool
    errors: list[str] = field(default_factory=list)

    def reject(self, msg: str) -> None:
        self.ok = False
        self.errors.append(msg)


def validate_coaching_report(
    report: CoachingReportBody,
    context: ReportContext,
) -> ValidationResult:
    result = ValidationResult(ok=True)
    available_metrics = context.available_metric_ids()
    available_events = context.available_event_ids()
    all_metrics = context.all_metric_ids()
    all_events = context.all_event_ids()
    metric_map = context.metric_by_id()
    event_map = context.event_by_id()

    if len(report.strengths) > 3:
        result.reject("exceeds_allowed_strength_count")
    if len(report.priority_improvements) > 3:
        result.reject("exceeds_allowed_priority_count")

    disclaimer_l = report.disclaimer.lower()
    if "video quality" not in disclaimer_l or "camera" not in disclaimer_l:
        result.reject("disclaimer_must_mention_video_quality_and_camera_angle")

    _scan_text_policy(report.summary, result, where="summary")
    _scan_text_policy(report.confidence_statement, result, where="confidence_statement")
    for i, s in enumerate(report.supporting_evidence):
        _scan_text_policy(s, result, where=f"supporting_evidence[{i}]")
    for i, s in enumerate(report.race_recommendations):
        _scan_text_policy(s, result, where=f"race_recommendations[{i}]")

    for i, obs in enumerate(report.strengths):
        _validate_observation(
            obs,
            result,
            where=f"strengths[{i}]",
            available_metrics=available_metrics,
            available_events=available_events,
            all_metrics=all_metrics,
            all_events=all_events,
            metric_map=metric_map,
            event_map=event_map,
        )

    for i, pri in enumerate(report.priority_improvements):
        if not (1 <= len(pri.drills) <= 2):
            result.reject(f"priority_improvements[{i}]_must_have_1_or_2_drills")
        for d_i, drill in enumerate(pri.drills):
            _scan_text_policy(drill, result, where=f"priority_improvements[{i}].drills[{d_i}]")
        _validate_observation(
            pri.observation,
            result,
            where=f"priority_improvements[{i}].observation",
            available_metrics=available_metrics,
            available_events=available_events,
            all_metrics=all_metrics,
            all_events=all_events,
            metric_map=metric_map,
            event_map=event_map,
        )

    return result


def _validate_observation(
    obs: CoachingObservation,
    result: ValidationResult,
    *,
    where: str,
    available_metrics: set[str],
    available_events: set[str],
    all_metrics: set[str],
    all_events: set[str],
    metric_map: dict,
    event_map: dict,
) -> None:
    _scan_text_policy(obs.text, result, where=where)

    if not obs.metric_ids and not obs.event_ids:
        result.reject(f"{where}_omits_evidence_ids")

    for mid in obs.metric_ids:
        if mid not in all_metrics:
            result.reject(f"{where}_unknown_metric_id:{mid}")
        elif mid not in available_metrics:
            result.reject(f"{where}_references_unavailable_metric:{mid}")
    for eid in obs.event_ids:
        if eid not in all_events:
            result.reject(f"{where}_unknown_event_id:{eid}")
        elif eid not in available_events:
            result.reject(f"{where}_references_unavailable_event:{eid}")

    # Confidence-aware language
    confs: list[float] = []
    for mid in obs.metric_ids:
        m = metric_map.get(mid)
        if m:
            confs.append(float(m.confidence))
    for eid in obs.event_ids:
        e = event_map.get(eid)
        if e:
            confs.append(float(e.confidence))
    min_conf = min(confs) if confs else 0.0
    band = obs.confidence_band
    if band == "unavailable":
        result.reject(f"{where}_unavailable_band_not_allowed_as_finding")
    if min_conf < 0.45 or band == "low":
        if not LOW_CUES.search(obs.text):
            result.reject(f"{where}_low_confidence_requires_cautious_wording")
        if CERTAINTY_PATTERNS.search(obs.text):
            result.reject(f"{where}_claims_certainty_from_low_confidence_evidence")
    elif (0.45 <= min_conf < 0.75) or band == "moderate":
        if not (MODERATE_CUES.search(obs.text) or LOW_CUES.search(obs.text)):
            result.reject(f"{where}_moderate_confidence_requires_suggestive_wording")

    # Invented / contradicting measurements
    known_values = _known_numeric_values(obs, metric_map, event_map)
    for match in MEASUREMENT_CLAIM.finditer(obs.text):
        num = float(match.group("num"))
        if not _near_any(num, known_values):
            result.reject(f"{where}_invented_measurement:{match.group(0)}")
    for match in BARE_STAT.finditer(obs.text):
        num = float(match.group("num"))
        if not _near_any(num, known_values):
            result.reject(f"{where}_invented_statistic:{num}")

    # Contradict referenced metric values when explicitly stated
    for mid in obs.metric_ids:
        m = metric_map.get(mid)
        if m is None or m.value is None:
            continue
        # If text contains the metric display/name and a number, it must match
        name_bits = [m.name.replace("_", " "), (m.display_name or "")]
        for bit in name_bits:
            if bit and bit.lower() in obs.text.lower():
                for nm in re.findall(r"\d+(?:\.\d+)?", obs.text):
                    val = float(nm)
                    if not _near(val, float(m.value)) and not _near_any(val, known_values):
                        # only flag if this number isn't explained by other known values
                        if abs(val - float(m.value)) / max(abs(float(m.value)), 1e-6) > 0.15:
                            # allow timestamps/frames from events
                            if not _near_any(val, known_values):
                                result.reject(f"{where}_contradicts_metric:{mid}:{nm}")


def _known_numeric_values(obs: CoachingObservation, metric_map: dict, event_map: dict) -> list[float]:
    vals: list[float] = []
    for mid in obs.metric_ids:
        m = metric_map.get(mid)
        if m and m.value is not None:
            vals.append(float(m.value))
        if m:
            vals.extend(float(x) for x in m.supporting_timestamps_ms)
            vals.extend(float(x) for x in m.supporting_frame_numbers)
    for eid in obs.event_ids:
        e = event_map.get(eid)
        if e is None:
            continue
        if e.timestamp_ms is not None:
            vals.append(float(e.timestamp_ms))
        if e.frame_number is not None:
            vals.append(float(e.frame_number))
        vals.extend(float(x) for x in e.supporting_timestamps_ms)
        vals.extend(float(x) for x in e.supporting_frames)
    return vals


def _near(a: float, b: float, *, rel: float = 0.08, abs_tol: float = 0.75) -> bool:
    return abs(a - b) <= max(abs_tol, rel * max(abs(b), 1.0))


def _near_any(num: float, values: list[float]) -> bool:
    return any(_near(num, v) for v in values)


def _scan_text_policy(text: str, result: ValidationResult, *, where: str) -> None:
    if MEDICAL_PATTERNS.search(text):
        result.reject(f"{where}_medical_claim")
    if SHAME_PATTERNS.search(text):
        result.reject(f"{where}_shame_or_negative_label")
    if CHILD_COMPARE_PATTERNS.search(text):
        result.reject(f"{where}_public_child_comparison")

"""Build Gemini-safe structured context from deterministic job results."""

from __future__ import annotations

from typing import Any

from app.domain.jobs import AnalysisJob
from app.services.report.schemas import (
    DeterministicEventRef,
    DeterministicMetricRef,
    EvidenceFrameRef,
    ReportContext,
)


def build_report_context(
    job: AnalysisJob,
    *,
    authorize_age_group: bool = False,
    authorize_previous_results: bool = False,
    previous_athlete_results: list[dict[str, Any]] | None = None,
    approved_standards: list[dict[str, Any]] | None = None,
    evidence_frame_paths: list[dict[str, Any]] | None = None,
) -> ReportContext:
    req = job.request_payload or {}
    athlete = req.get("athlete") or {}
    event = req.get("event") or {}
    options = req.get("options") or {}

    metrics: list[DeterministicMetricRef] = []
    events: list[DeterministicEventRef] = []

    for source, payload in (
        ("butterfly", job.butterfly),
        ("underwater", job.underwater),
        ("turn", job.turn),
        ("finish", job.finish),
    ):
        if not payload:
            continue
        for m in payload.get("metrics") or []:
            metrics.append(_metric_ref(source, m))
        for e in payload.get("events") or []:
            events.append(_event_ref(source, e))

    # Tracking-only Elite runs (pose/M5–M7 off) still need citeable metric IDs
    # so Gemini / local fallback coaching can pass validation.
    metrics.extend(_tracking_metric_refs(job))
    events.extend(_tracking_event_refs(job))

    evidence: list[EvidenceFrameRef] = []
    for item in evidence_frame_paths or []:
        evidence.append(
            EvidenceFrameRef(
                frame_number=item.get("frame_number"),
                path=item.get("path"),
                label=item.get("label"),
                metric_ids=list(item.get("metric_ids") or []),
                event_ids=list(item.get("event_ids") or []),
            )
        )
    # Derive light evidence refs from available event frames (paths optional)
    if not evidence:
        for e in events:
            if e.frame_number is not None and not e.unavailable_reason:
                evidence.append(
                    EvidenceFrameRef(
                        frame_number=e.frame_number,
                        label=e.event_type,
                        event_ids=[e.event_id],
                    )
                )
                if len(evidence) >= 8:
                    break

    stroke = str(
        event.get("stroke")
        or options.get("stroke_hint")
        or ((job.butterfly or {}).get("summary") or {}).get("stroke")
        or "unknown"
    )

    return ReportContext(
        job_id=job.job_id,
        video_id=job.video_id,
        stroke_type=stroke,
        course=event.get("course"),
        race_distance_m=event.get("distance_m"),
        athlete_age_group=athlete.get("age_group") if authorize_age_group else None,
        athlete_display_name=athlete.get("display_name"),
        analysis_limitations=list(job.limitations or []),
        metrics=metrics,
        events=events,
        evidence_frames=evidence,
        previous_athlete_results=list(previous_athlete_results or [])
        if authorize_previous_results
        else [],
        approved_standards=list(approved_standards or []),
        authorize_age_group=authorize_age_group,
        authorize_previous_results=authorize_previous_results,
    )


def _metric_ref(source: str, m: dict[str, Any]) -> DeterministicMetricRef:
    name = str(m.get("name") or "metric")
    metric_id = str(m.get("metric_id") or f"{source}:{name}")
    return DeterministicMetricRef(
        metric_id=metric_id,
        name=name,
        display_name=m.get("display_name"),
        value=m.get("value"),
        unit=m.get("unit"),
        confidence=float(m.get("confidence") or 0.0),
        confidence_label=str(m.get("confidence_label") or "unavailable"),
        classification=m.get("classification"),
        method=m.get("method"),
        unavailable_reason=m.get("unavailable_reason"),
        quality_flags=list(m.get("quality_flags") or []),
        limitations=list(m.get("limitations") or []),
        supporting_frame_numbers=list(m.get("supporting_frame_numbers") or []),
        supporting_timestamps_ms=list(m.get("supporting_timestamps_ms") or []),
    )


def _event_ref(source: str, e: dict[str, Any]) -> DeterministicEventRef:
    et = str(e.get("event_type") or "event")
    # Prefer explicit id; else stable source:type:frame
    frame = e.get("frame_number")
    event_id = str(e.get("event_id") or f"{source}:{et}:{frame if frame is not None else 'na'}")
    return DeterministicEventRef(
        event_id=event_id,
        event_type=et,
        timestamp_ms=e.get("timestamp_ms"),
        frame_number=frame,
        confidence=float(e.get("confidence") or 0.0),
        confidence_label=str(e.get("confidence_label") or "unavailable"),
        method=e.get("method"),
        unavailable_reason=e.get("unavailable_reason"),
        quality_flags=list(e.get("quality_flags") or []),
        limitations=list(e.get("limitations") or []),
        supporting_frames=list(e.get("supporting_frames") or []),
        supporting_timestamps_ms=list(e.get("supporting_timestamps_ms") or []),
    )


def collect_deterministic_payloads(job: AnalysisJob) -> tuple[list[dict], list[dict]]:
    metrics: list[dict] = []
    events: list[dict] = []
    for payload in (job.butterfly, job.underwater, job.turn, job.finish):
        if not payload:
            continue
        metrics.extend(list(payload.get("metrics") or []))
        events.extend(list(payload.get("events") or []))
    for ref in _tracking_metric_refs(job):
        metrics.append(ref.model_dump())
    for ref in _tracking_event_refs(job):
        events.append(ref.model_dump())
    return metrics, events


def _tracking_metric_refs(job: AnalysisJob) -> list[DeterministicMetricRef]:
    tracking = job.tracking or {}
    quality = tracking.get("quality_summary") or {}
    target = tracking.get("target") or {}
    if not quality and not target:
        return []

    coverage = quality.get("target_coverage")
    if coverage is None:
        coverage = target.get("target_coverage")
    try:
        coverage_f = float(coverage) if coverage is not None else None
    except (TypeError, ValueError):
        coverage_f = None

    processed = quality.get("processed_frames")
    detected = quality.get("frames_with_detections")
    try:
        processed_i = int(processed) if processed is not None else None
    except (TypeError, ValueError):
        processed_i = None
    try:
        detected_i = int(detected) if detected is not None else None
    except (TypeError, ValueError):
        detected_i = None

    conf = float(target.get("target_identity_confidence") or quality.get("mean_confidence") or 0.55)
    conf = max(0.0, min(1.0, conf))
    label = "high" if conf >= 0.75 else "moderate" if conf >= 0.45 else "low"

    out: list[DeterministicMetricRef] = []
    if coverage_f is not None:
        out.append(
            DeterministicMetricRef(
                metric_id="tracking:target_coverage",
                name="target_coverage",
                display_name="Swimmer visibility coverage",
                value=round(coverage_f, 3),
                unit="fraction",
                confidence=conf,
                confidence_label=label,
                classification="measured",
                method="rtmdet_tracking",
            )
        )
    if processed_i is not None:
        out.append(
            DeterministicMetricRef(
                metric_id="tracking:processed_frames",
                name="processed_frames",
                display_name="Frames analyzed",
                value=processed_i,
                unit="frames",
                confidence=0.9,
                confidence_label="high",
                classification="measured",
                method="rtmdet_tracking",
            )
        )
    if detected_i is not None:
        out.append(
            DeterministicMetricRef(
                metric_id="tracking:frames_with_detections",
                name="frames_with_detections",
                display_name="Frames with swimmer detections",
                value=detected_i,
                unit="frames",
                confidence=conf,
                confidence_label=label,
                classification="measured",
                method="rtmdet_tracking",
            )
        )
    return out


def _tracking_event_refs(job: AnalysisJob) -> list[DeterministicEventRef]:
    tracking = job.tracking or {}
    target = tracking.get("target") or {}
    observations = list(target.get("observations") or [])
    if not observations:
        return []
    first = observations[0] if isinstance(observations[0], dict) else {}
    last = observations[-1] if isinstance(observations[-1], dict) else {}
    out: list[DeterministicEventRef] = []
    if first.get("frame_number") is not None:
        out.append(
            DeterministicEventRef(
                event_id=f"tracking:first_target:{first.get('frame_number')}",
                event_type="first_target_observation",
                timestamp_ms=first.get("timestamp_ms"),
                frame_number=int(first["frame_number"]),
                confidence=float(first.get("confidence") or 0.6),
                confidence_label="moderate",
                method="rtmdet_tracking",
            )
        )
    if last.get("frame_number") is not None and last.get("frame_number") != first.get(
        "frame_number"
    ):
        out.append(
            DeterministicEventRef(
                event_id=f"tracking:last_target:{last.get('frame_number')}",
                event_type="last_target_observation",
                timestamp_ms=last.get("timestamp_ms"),
                frame_number=int(last["frame_number"]),
                confidence=float(last.get("confidence") or 0.6),
                confidence_label="moderate",
                method="rtmdet_tracking",
            )
        )
    return out

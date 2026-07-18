"""Local coaching report when Gemini is unavailable or rejects the key."""

from __future__ import annotations

from app.services.report.schemas import (
    CoachingObservation,
    CoachingReportBody,
    PriorityImprovement,
    ReportContext,
)


def build_local_tracking_report(context: ReportContext) -> CoachingReportBody:
    """Coach-facing tips from tracking metrics only (no Gemini call)."""
    metric_ids = sorted(context.available_metric_ids()) or sorted(context.all_metric_ids())
    event_ids = sorted(context.available_event_ids()) or sorted(context.all_event_ids())
    cite_m = metric_ids[:2] or ["tracking:target_coverage"]
    cite_e = event_ids[:1]

    coverage = None
    for m in context.metrics:
        if m.metric_id == "tracking:target_coverage" and m.value is not None:
            try:
                coverage = float(m.value)
            except (TypeError, ValueError):
                coverage = None
            break

    stroke = (context.stroke_type or "swim").replace("_", " ")
    if coverage is not None and coverage >= 0.35:
        strength_text = (
            f"The analysis suggests a clear primary swimmer track was held for much of "
            f"this {stroke} clip, which is a solid base for technique review."
        )
        band: str = "moderate"
    else:
        strength_text = (
            "The available frames may indicate moments where the swimmer is visible "
            "enough to review body line and stroke timing from the side view."
        )
        band = "low"

    improve_text = (
        "The available frames may indicate splash, underwater phases, or camera angle "
        "hid the body at times — re-film from the side with the full body in frame "
        "for clearer coaching detail."
    )
    if coverage is not None and coverage >= 0.45:
        improve_text = (
            "The analysis suggests focusing the next review on consistent side-on framing "
            "so stroke phases stay visible from start to finish."
        )
        band_imp = "moderate"
    else:
        band_imp = "low"

    low_cue = "The available frames may indicate"
    if band == "low" and not strength_text.startswith(low_cue):
        strength_text = f"{low_cue} " + strength_text[0].lower() + strength_text[1:]

    return CoachingReportBody(
        summary=(
            f"Tracking review for this {stroke} clip is ready. "
            "Use the strengths and drills below while Gemini coaching is unavailable."
        ),
        strengths=[
            CoachingObservation(
                text=strength_text,
                confidence_band=band,  # type: ignore[arg-type]
                metric_ids=cite_m,
                event_ids=cite_e,
            )
        ],
        priority_improvements=[
            PriorityImprovement(
                observation=CoachingObservation(
                    text=improve_text,
                    confidence_band=band_imp,  # type: ignore[arg-type]
                    metric_ids=cite_m,
                    event_ids=cite_e,
                ),
                drills=[
                    "Film one length from the side, camera steady, full body visible.",
                    "Repeat the same race segment with less zoom so underwater phases stay in frame.",
                ],
            )
        ],
        supporting_evidence=[
            "Evidence comes from Elite swimmer tracking on this PC (not raw Gemini video review)."
        ],
        race_recommendations=[
            f"Keep the next {stroke} clip short and side-on for the clearest feedback loop."
        ],
        limitations=[
            "Local tracking coaching used because Gemini report was unavailable.",
            "Estimates depend on video quality and camera angle.",
        ],
        confidence_statement=(
            "Confidence follows tracking visibility on this clip. "
            "Splash, underwater segments, or tight zoom can lower certainty."
        ),
        disclaimer=(
            "These tips depend on video quality and camera angle. "
            "They are practice guidance, not medical advice."
        ),
    )

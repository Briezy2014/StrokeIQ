"""Prompt construction for confidence-aware Gemini coaching reports."""

from __future__ import annotations

import json
from typing import Any

from app.services.report.schemas import PROMPT_VERSION, ReportContext

SYSTEM_PROMPT = """You are Elite Video Lab's swim coach assistant.
Write for a swimmer, parent, and coach. Be clear, brief, and useful.

Hard rules:
1. Use ONLY the structured analysis JSON provided. Do not invent exact splits, stroke counts, angles, or distances that are not in the JSON.
2. Every strength and priority improvement MUST reference one or more metric_ids and/or event_ids from the JSON.
3. Never analyze raw video. You do not receive the full video.
4. Do not make medical, injury, pain, or diagnostic claims.
5. Do not shame, insult, or negatively label the swimmer.
6. Do not compare the athlete publicly to another child by name or ranking.
7. Do not present unavailable metrics as findings.
8. Language: write clear coach talk. Start strengths with "Pro:" and fixes with "Con:".
   Do NOT spam phrases like "the available frames may indicate" or "the analysis suggests".
   Avoid fake certainty words (definitely, proven, guaranteed). Soft estimates are OK.
9. Produce at most TWO strengths and at most TWO priority improvements.
10. Drills must be DRYLAND ONLY (no pool/swim drills). One or two per improvement.
11. Include a confidence statement and a disclaimer that estimates depend on video quality and camera angle.
12. Race recommendations: one next-race cue a swimmer can understand, plus an optional
    estimated time-drop range if the main cue sticks (say it is an estimate, not a guarantee).
13. Be specific to the stroke/distance. No repetitive filler. No engineer jargon.

Return structured JSON matching the required schema only.
"""


def build_user_prompt(context: ReportContext) -> str:
    payload = _context_payload(context)
    return (
        f"Prompt version: {PROMPT_VERSION}\n"
        "Write a concise athlete coaching report from this validated analysis JSON.\n"
        "Reference only IDs present in metrics/events. Do not invent values.\n\n"
        f"{json.dumps(payload, indent=2, default=str)}"
    )


def _context_payload(context: ReportContext) -> dict[str, Any]:
    athlete: dict[str, Any] = {}
    if context.athlete_display_name:
        athlete["display_name"] = context.athlete_display_name
    if context.authorize_age_group and context.athlete_age_group:
        athlete["age_group"] = context.athlete_age_group

    previous = context.previous_athlete_results if context.authorize_previous_results else []

    # Send available metrics/events for findings; still list unavailable IDs as excluded.
    available_metrics = [
        m.model_dump()
        for m in context.metrics
        if m.value is not None and not m.unavailable_reason
    ]
    unavailable_metric_ids = [
        m.metric_id
        for m in context.metrics
        if m.value is None or m.unavailable_reason
    ]
    available_events = [
        e.model_dump()
        for e in context.events
        if e.frame_number is not None and not e.unavailable_reason
    ]
    unavailable_event_ids = [
        e.event_id
        for e in context.events
        if e.frame_number is None or e.unavailable_reason
    ]

    return {
        "job_id": context.job_id,
        "video_id": context.video_id,
        "stroke_type": context.stroke_type,
        "course": context.course,
        "race_distance_m": context.race_distance_m,
        "athlete": athlete or None,
        "analysis_limitations": context.analysis_limitations,
        "metrics": available_metrics,
        "events": available_events,
        "do_not_use_as_findings": {
            "unavailable_metric_ids": unavailable_metric_ids,
            "unavailable_event_ids": unavailable_event_ids,
        },
        "evidence_frames": [e.model_dump() for e in context.evidence_frames],
        "previous_athlete_results": previous,
        "approved_standards": context.approved_standards,
        "output_requirements": {
            "strengths_count": "1-3",
            "priority_improvements_max": 3,
            "drills_per_priority": "1-2",
            "must_include_disclaimer_about_video_quality_and_camera_angle": True,
        },
    }

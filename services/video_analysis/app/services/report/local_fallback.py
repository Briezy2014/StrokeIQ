"""Clear local coaching report when Gemini is unavailable or too slow.

Written for swimmers, parents, and coaches - not engineers.
Dryland drills only. No hedge-spam prefixes.
"""

from __future__ import annotations

from app.services.report.schemas import (
    CoachingObservation,
    CoachingReportBody,
    PriorityImprovement,
    ReportContext,
)


def build_local_tracking_report(context: ReportContext) -> CoachingReportBody:
    """Coach-facing breakdown from tracking + stroke context (no Gemini)."""
    metric_ids = sorted(context.available_metric_ids()) or sorted(context.all_metric_ids())
    event_ids = sorted(context.available_event_ids()) or sorted(context.all_event_ids())
    cite_m = metric_ids[:3] or ["tracking:target_coverage"]
    cite_e = event_ids[:2]

    coverage = _metric_value(context, "tracking:target_coverage")
    stroke_key = _normalize_stroke(context.stroke_type)
    stroke = stroke_key.replace("_", " ")
    distance = context.race_distance_m
    distance_bit = f"{distance}m " if distance else ""
    athlete = (context.athlete_display_name or "the swimmer").strip() or "the swimmer"

    visibility = "clear" if (coverage is not None and coverage >= 0.45) else (
        "okay" if (coverage is not None and coverage >= 0.25) else "limited"
    )

    pack = _stroke_pack(stroke_key)
    strengths = [
        _obs(pack["strengths"][0], cite_m, cite_e),
        _obs(pack["strengths"][1], cite_m, cite_e),
    ]

    improvements: list[PriorityImprovement] = []
    for item in pack["improvements"][:2]:
        improvements.append(
            PriorityImprovement(
                observation=_obs(item["text"], cite_m, cite_e),
                drills=item["drills"][:2],
            )
        )

    if visibility == "limited":
        # Keep stroke cues, but lead with one filming note as a con - not as a "drill".
        filming_note = PriorityImprovement(
            observation=_obs(
                f"Video quality made parts of this {stroke} hard to judge "
                f"(splash, underwater, or camera angle). A steadier side-view clip "
                f"will make the next review sharper.",
                cite_m,
                cite_e,
            ),
            drills=pack["improvements"][0]["drills"][:2],
        )
        improvements = [filming_note, *improvements[:1]]

    time_drop = pack["time_drop"]
    summary = (
        f"Quick coach read on this {distance_bit}{stroke} clip for {athlete}: "
        f"one clear strength, one main fix, dryland drills, and a next-race cue. "
        f"Video clarity looked {visibility}."
    )

    return CoachingReportBody(
        summary=summary,
        strengths=strengths[:2],
        priority_improvements=improvements[:2],
        supporting_evidence=[
            f"Stroke: {stroke}.",
            f"Video clarity for tracking: {visibility}.",
            "Tips use Elite tracking on this PC plus stroke-specific coaching standards.",
        ],
        race_recommendations=[
            pack["next_race_cue"],
            pack["next_race_plan"],
            time_drop,
        ],
        limitations=[
            "This report uses SwimIQ local coaching when the Gemini AI model is unavailable.",
            "Estimates depend on video quality and camera angle.",
            "Splash and underwater segments can hide the body.",
        ],
        confidence_statement=(
            "Treat this as practice guidance from the clearest parts of the clip. "
            "Better side-view video raises confidence on the next review."
        ),
        disclaimer=(
            "These tips depend on video quality and camera angle. "
            "They are practice guidance for training and racing, not medical advice. "
            "Any time-drop note is an estimate, not a guarantee."
        ),
    )


def _metric_value(context: ReportContext, metric_id: str) -> float | None:
    for m in context.metrics:
        if m.metric_id == metric_id and m.value is not None:
            try:
                return float(m.value)
            except (TypeError, ValueError):
                return None
    return None


def _normalize_stroke(raw: str | None) -> str:
    s = (raw or "unknown").strip().lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "fly": "butterfly",
        "free": "freestyle",
        "back": "backstroke",
        "breast": "breaststroke",
        "im": "individual_medley",
    }
    return aliases.get(
        s,
        s
        if s
        in {
            "butterfly",
            "freestyle",
            "backstroke",
            "breaststroke",
            "individual_medley",
        }
        else "unknown",
    )


def _obs(
    text: str,
    metric_ids: list[str],
    event_ids: list[str],
) -> CoachingObservation:
    """Clear coach language - never prepend hedge spam."""
    return CoachingObservation(
        text=text.strip(),
        confidence_band="moderate",
        metric_ids=metric_ids,
        event_ids=event_ids,
    )


def _stroke_pack(stroke: str) -> dict:
    packs: dict[str, dict] = {
        "butterfly": {
            "strengths": [
                "Pro: stroke rhythm is readable in the clearer frames - keep that connected "
                "kick-and-pull timing.",
                "Pro: body-line moments look long and forward when the swimmer is visible - "
                "copy those frames in practice.",
            ],
            "improvements": [
                {
                    "text": (
                        "Con: hips can sink when the head lifts to breathe. "
                        "Work a tighter body line into the breath."
                    ),
                    "drills": [
                        "Dryland: 3 x 20s hollow-body holds, then 10 Superman pulses.",
                        "Dryland: banded pull-aparts 3 x 12 focusing on chest press and long arms.",
                    ],
                },
                {
                    "text": (
                        "Con: the second kick can lag hand entry, which costs speed between strokes. "
                        "Time kick-on-entry as the main fix."
                    ),
                    "drills": [
                        "Dryland: dolphin kick on your back (floor), arms by ears, 4 x 20s.",
                        "Dryland: jump-rope single-unders 3 x 45s for rhythm without pausing.",
                    ],
                },
            ],
            "next_race_cue": (
                "Next race cue: kick on entry, press the chest, breathe late and low."
            ),
            "next_race_plan": (
                "First 15m: tight underwater dolphins, then break out into a tempo you can hold."
            ),
            "time_drop": (
                "If the body-line and kick-on-entry cues stick, many age-group 50 fly swimmers "
                "can see about 0.3 to 0.8 seconds come off - results vary with race execution."
            ),
        },
        "freestyle": {
            "strengths": [
                "Pro: forward swim rhythm is clear enough to coach - protect a quiet head.",
                "Pro: early catch windows show up in the clearer side frames - keep that pressure.",
            ],
            "improvements": [
                {
                    "text": (
                        "Con: side-to-side head movement can drop the hips. "
                        "Quiet head is the priority fix."
                    ),
                    "drills": [
                        "Dryland: wall angels 3 x 10 with ribs down and chin neutral.",
                        "Dryland: dead-bug 3 x 8/side for a stable core while arms move.",
                    ],
                },
                {
                    "text": (
                        "Con: a late catch shortens each stroke. "
                        "Feel earlier water pressure before the pull."
                    ),
                    "drills": [
                        "Dryland: band face-pulls 3 x 12 for posture and early catch shape.",
                        "Dryland: plank shoulder taps 3 x 20 total, hips quiet.",
                    ],
                },
            ],
            "next_race_cue": (
                "Next race cue: quiet head, early catch, kick that does not stop in the third 25."
            ),
            "next_race_plan": (
                "Breakout: tight streamline, then accelerate into your race stroke rate."
            ),
            "time_drop": (
                "If head position and early catch improve, many age-group 50 free swimmers "
                "can see about 0.2 to 0.6 seconds come off - results vary with race execution."
            ),
        },
        "backstroke": {
            "strengths": [
                "Pro: body position looks coachable - keep hips high and the kick continuous.",
                "Pro: arm tempo is steady enough to rehearse race rhythm.",
            ],
            "improvements": [
                {
                    "text": (
                        "Con: a big kick can bounce the hips when arms accelerate. "
                        "Keep the kick smaller and steadier."
                    ),
                    "drills": [
                        "Dryland: flutter-kick on your back (floor) 4 x 20s, toes pointed.",
                        "Dryland: glute bridges 3 x 12 for hip height support.",
                    ],
                },
                {
                    "text": (
                        "Con: hand entry can miss above the shoulder, delaying the catch. "
                        "Enter cleaner and accelerate the finish."
                    ),
                    "drills": [
                        "Dryland: band straight-arm pulldowns 3 x 10/side.",
                        "Dryland: Y-T-W raises 2 x 8 each shape, light weight or no weight.",
                    ],
                },
            ],
            "next_race_cue": (
                "Next race cue: hips up, kick steady, enter above the shoulder."
            ),
            "next_race_plan": (
                "Protect underwater speed off each wall before settling into stroke rate."
            ),
            "time_drop": (
                "If kick size and entry improve, many age-group 50 back swimmers "
                "can see about 0.2 to 0.7 seconds come off - results vary with race execution."
            ),
        },
        "breaststroke": {
            "strengths": [
                "Pro: pull-breathe-kick timing is reviewable - keep the glide honest, not long.",
                "Pro: forward line after the kick is a strength to protect when tired.",
            ],
            "improvements": [
                {
                    "text": (
                        "Con: a flat shoot after the kick kills speed. "
                        "Shoot to a tighter streamline."
                    ),
                    "drills": [
                        "Dryland: streamline holds against a wall 4 x 20s, arms glued to ears.",
                        "Dryland: frog-stretch ankle mobility 2 x 30s/side.",
                    ],
                },
                {
                    "text": (
                        "Con: hands can pause after the breath. "
                        "Accelerate hands forward so the next pull starts on time."
                    ),
                    "drills": [
                        "Dryland: med-ball chest pass to a partner/wall 3 x 8 (soft ball).",
                        "Dryland: squat-to-stand with arm shoot 3 x 10 focusing on fast hands forward.",
                    ],
                },
            ],
            "next_race_cue": (
                "Next race cue: pull, breathe, kick, shoot - no pause before hands go forward."
            ),
            "next_race_plan": (
                "Off the wall: strong pullout, then break into race timing you can hold."
            ),
            "time_drop": (
                "If the shoot and hand-recovery timing improve, many age-group 50 breast swimmers "
                "can see about 0.3 to 0.9 seconds come off - results vary with race execution."
            ),
        },
    }
    default = {
        "strengths": [
            "Pro: the swimmer track is clear enough for a useful race review of body line and timing.",
            "Pro: clearer frames show moments worth repeating - long line and forward intent.",
        ],
        "improvements": [
            {
                "text": (
                    "Con: pick one timing cue for the next race and ignore everything else under pressure."
                ),
                "drills": [
                    "Dryland: 3 x 30s plank, eyes on one written cue card in front of you.",
                    "Dryland: jump-rope 3 x 45s while repeating your one race cue out loud.",
                ],
            },
            {
                "text": (
                    "Con: film the next clip from true side so stroke phases stay visible start to finish."
                ),
                "drills": [
                    "Dryland: streamline holds 4 x 20s.",
                    "Dryland: hollow holds 3 x 20s for a tighter body line.",
                ],
            },
        ],
        "next_race_cue": "Next race cue: one technical focus only - write it on your hand if needed.",
        "next_race_plan": "Warm up the exact race segment you just filmed before you step up.",
        "time_drop": (
            "If one clear cue sticks through the whole race, many age-group 50 swimmers "
            "can see about 0.2 to 0.6 seconds come off - results vary with race execution."
        ),
    }
    return packs.get(stroke, default)

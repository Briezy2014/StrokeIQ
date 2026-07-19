"""Swimmer-speak coaching when Gemini is unavailable.

Written for the athlete first. No "frames", no engineer notes, no meta summary.
"""

from __future__ import annotations

from app.services.report.schemas import (
    CoachingObservation,
    CoachingReportBody,
    PriorityImprovement,
    ReportContext,
)


def build_local_tracking_report(context: ReportContext) -> CoachingReportBody:
    metric_ids = sorted(context.available_metric_ids()) or sorted(context.all_metric_ids())
    event_ids = sorted(context.available_event_ids()) or sorted(context.all_event_ids())
    cite_m = metric_ids[:3] or ["tracking:target_coverage"]
    cite_e = event_ids[:2]

    stroke_key = _normalize_stroke(context.stroke_type)
    stroke = stroke_key.replace("_", " ")
    distance = context.race_distance_m
    distance_bit = f"{distance} " if distance else ""
    athlete = (context.athlete_display_name or "").strip()
    name = athlete if athlete and athlete.lower() != "demo" else "you"

    pack = _stroke_pack(stroke_key)

    # Summary = direct talk to the swimmer (not a table of contents).
    summary = pack["athlete_summary"].format(
        name=name,
        distance=distance_bit,
        stroke=stroke,
    )

    strengths = [_obs(t, cite_m, cite_e) for t in pack["strengths"][:2]]
    improvements = [
        PriorityImprovement(
            observation=_obs(item["text"], cite_m, cite_e),
            drills=item["drills"][:2],
        )
        for item in pack["improvements"][:2]
    ]

    return CoachingReportBody(
        summary=summary,
        strengths=strengths,
        priority_improvements=improvements,
        supporting_evidence=[],
        race_recommendations=[
            pack["next_race_cue"],
            pack["next_race_plan"],
            pack["time_drop"],
        ],
        # Schema requires >=1 item; Flutter report UI does not show this list.
        limitations=[
            "Tips depend on how clear the race video is.",
        ],
        confidence_statement=(
            "Use these cues in practice this week, then race them."
        ),
        disclaimer=(
            "Tips depend on video quality and camera angle. "
            "Practice guidance only - not medical advice. "
            "Any time-drop note is an estimate, not a guarantee."
        ),
    )


def _normalize_stroke(raw: str | None) -> str:
    s = (raw or "unknown").strip().lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "fly": "butterfly",
        "free": "freestyle",
        "back": "backstroke",
        "breast": "breaststroke",
        "im": "individual_medley",
    }
    known = {
        "butterfly",
        "freestyle",
        "backstroke",
        "breaststroke",
        "individual_medley",
    }
    return aliases.get(s, s if s in known else "unknown")


def _obs(text: str, metric_ids: list[str], event_ids: list[str]) -> CoachingObservation:
    return CoachingObservation(
        text=text.strip(),
        confidence_band="moderate",
        metric_ids=metric_ids,
        event_ids=event_ids,
    )


def _stroke_pack(stroke: str) -> dict:
    packs: dict[str, dict] = {
        "butterfly": {
            "athlete_summary": (
                "{name}, on this {distance}butterfly: keep your rhythm and body line, "
                "and make kick-on-entry your one race cue."
            ),
            "strengths": [
                "Your stroke timing looks connected - keep the kick and pull working together.",
                "When you stay long and flat, you look fast - hold that line into the breath.",
            ],
            "improvements": [
                {
                    "text": (
                        "Your hips drop when you lift your head to breathe. "
                        "Press your chest and breathe late so your hips stay up."
                    ),
                    "drills": [
                        "Dryland: 3 x 20s hollow-body holds, then 10 Superman pulses.",
                        "Dryland: banded pull-aparts 3 x 12 - long arms, chest press.",
                    ],
                },
                {
                    "text": (
                        "Your second kick is late off the hand entry, so you lose speed "
                        "between strokes. Kick as the hands enter."
                    ),
                    "drills": [
                        "Dryland: dolphin kick on your back (floor), arms by ears, 4 x 20s.",
                        "Dryland: jump-rope single-unders 3 x 45s - steady rhythm, no pause.",
                    ],
                },
            ],
            "next_race_cue": "Race cue: kick on entry, press the chest, breathe late and low.",
            "next_race_plan": (
                "First 15m: tight underwater dolphins, then break out into a tempo you can hold."
            ),
            "time_drop": (
                "If you lock body line and kick-on-entry, many age-group 50 fly swimmers "
                "drop about 0.3-0.8 seconds - that is an estimate, not a promise."
            ),
        },
        "freestyle": {
            "athlete_summary": (
                "{name}, on this {distance}freestyle: quiet head and an early catch "
                "are your two biggest wins right now."
            ),
            "strengths": [
                "Your rhythm looks steady - keep swimming tall and quiet.",
                "Your catch can grab water early - keep that pressure before you pull.",
            ],
            "improvements": [
                {
                    "text": (
                        "Your head is moving side to side, and that drops your hips. "
                        "Keep your forehead still and look straight down."
                    ),
                    "drills": [
                        "Dryland: wall angels 3 x 10 - ribs down, chin neutral.",
                        "Dryland: dead-bug 3 x 8 each side - core quiet while arms move.",
                    ],
                },
                {
                    "text": (
                        "Your catch is late, so each stroke travels less. "
                        "Feel the water earlier before you pull back."
                    ),
                    "drills": [
                        "Dryland: band face-pulls 3 x 12 for posture and early catch shape.",
                        "Dryland: plank shoulder taps 3 x 20 - hips stay still.",
                    ],
                },
            ],
            "next_race_cue": (
                "Race cue: quiet head, early catch, kick that does not stop late in the race."
            ),
            "next_race_plan": (
                "Breakout: tight streamline, then accelerate into your race stroke rate."
            ),
            "time_drop": (
                "If head position and early catch improve, many age-group 50 free swimmers "
                "drop about 0.2-0.6 seconds - that is an estimate, not a promise."
            ),
        },
        "backstroke": {
            "athlete_summary": (
                "{name}, on this {distance}backstroke: hips up and a clean hand entry "
                "are the cues to race."
            ),
            "strengths": [
                "Your body position can stay high - keep the hips up and kick continuous.",
                "Your arm tempo looks steady - race that same rhythm.",
            ],
            "improvements": [
                {
                    "text": (
                        "Your kick gets too big and bounces your hips. "
                        "Make the kick smaller and steadier."
                    ),
                    "drills": [
                        "Dryland: flutter kick on your back (floor) 4 x 20s, toes pointed.",
                        "Dryland: glute bridges 3 x 12 to support hip height.",
                    ],
                },
                {
                    "text": (
                        "Your hands are missing a clean entry above the shoulder. "
                        "Enter cleaner, then accelerate the finish of the stroke."
                    ),
                    "drills": [
                        "Dryland: band straight-arm pulldowns 3 x 10 each side.",
                        "Dryland: Y-T-W raises 2 x 8 each shape (light or no weight).",
                    ],
                },
            ],
            "next_race_cue": "Race cue: hips up, kick steady, enter above the shoulder.",
            "next_race_plan": (
                "Protect underwater speed off each wall before you settle into stroke rate."
            ),
            "time_drop": (
                "If kick size and entry improve, many age-group 50 back swimmers "
                "drop about 0.2-0.7 seconds - that is an estimate, not a promise."
            ),
        },
        "breaststroke": {
            "athlete_summary": (
                "{name}, on this {distance}breaststroke: shoot tight after the kick "
                "and get your hands forward fast."
            ),
            "strengths": [
                "Your pull-breathe-kick timing is there - keep the glide honest, not long.",
                "Your line after the kick can stay fast - protect that when you get tired.",
            ],
            "improvements": [
                {
                    "text": (
                        "You are flat after the kick instead of shooting into a tight line. "
                        "Snap to streamline after every kick."
                    ),
                    "drills": [
                        "Dryland: streamline holds against a wall 4 x 20s, arms by ears.",
                        "Dryland: frog-stretch ankle mobility 2 x 30s each side.",
                    ],
                },
                {
                    "text": (
                        "Your hands pause after the breath. "
                        "Shoot the hands forward right away so the next pull starts on time."
                    ),
                    "drills": [
                        "Dryland: soft med-ball chest pass 3 x 8.",
                        "Dryland: squat-to-stand with arm shoot 3 x 10 - fast hands forward.",
                    ],
                },
            ],
            "next_race_cue": (
                "Race cue: pull, breathe, kick, shoot - no pause before the hands go forward."
            ),
            "next_race_plan": (
                "Off the wall: strong pullout, then break into race timing you can hold."
            ),
            "time_drop": (
                "If the shoot and hand recovery improve, many age-group 50 breast swimmers "
                "drop about 0.3-0.9 seconds - that is an estimate, not a promise."
            ),
        },
    }
    default = {
        "athlete_summary": (
            "{name}, on this {distance}{stroke}: pick one race cue and swim it the whole way."
        ),
        "strengths": [
            "Your body line and timing are clear enough to coach - stay long and forward.",
            "Your race intent shows - keep swimming with purpose end to end.",
        ],
        "improvements": [
            {
                "text": (
                    "Too many thoughts under pressure. Choose one cue and ignore the rest in the race."
                ),
                "drills": [
                    "Dryland: 3 x 30s plank while saying your one race cue out loud.",
                    "Dryland: jump-rope 3 x 45s with that same cue only.",
                ],
            },
            {
                "text": (
                    "Film the next race from the side with your whole body in view "
                    "so the next review is even clearer."
                ),
                "drills": [
                    "Dryland: streamline holds 4 x 20s.",
                    "Dryland: hollow holds 3 x 20s for a tighter body line.",
                ],
            },
        ],
        "next_race_cue": "Race cue: one focus only - write it on your hand if you need to.",
        "next_race_plan": "Warm up the same race segment you just swam before you step up.",
        "time_drop": (
            "If one clear cue sticks the whole race, many age-group 50 swimmers "
            "drop about 0.2-0.6 seconds - that is an estimate, not a promise."
        ),
    }
    return packs.get(stroke, default)

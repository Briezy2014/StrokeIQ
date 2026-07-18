"""Rich local coaching report when Gemini is unavailable or too slow."""

from __future__ import annotations

from app.services.report.schemas import (
    CoachingObservation,
    CoachingReportBody,
    PriorityImprovement,
    ReportContext,
)


def build_local_tracking_report(context: ReportContext) -> CoachingReportBody:
    """Full coach-facing breakdown from tracking + stroke context (no Gemini)."""
    metric_ids = sorted(context.available_metric_ids()) or sorted(context.all_metric_ids())
    event_ids = sorted(context.available_event_ids()) or sorted(context.all_event_ids())
    cite_m = metric_ids[:3] or ["tracking:target_coverage"]
    cite_e = event_ids[:2]

    coverage = _metric_value(context, "tracking:target_coverage")
    processed = _metric_value(context, "tracking:processed_frames")
    detected = _metric_value(context, "tracking:frames_with_detections")
    stroke_key = _normalize_stroke(context.stroke_type)
    stroke = stroke_key.replace("_", " ")
    distance = context.race_distance_m
    distance_bit = f"{distance}m " if distance else ""

    visibility = "solid" if (coverage is not None and coverage >= 0.45) else (
        "usable" if (coverage is not None and coverage >= 0.25) else "limited"
    )
    band: str = "moderate" if visibility in {"solid", "usable"} else "low"
    low = band == "low"

    pack = _stroke_pack(stroke_key)
    strengths = [
        _obs(pack["strengths"][0], cite_m, cite_e, band, low),
        _obs(pack["strengths"][1], cite_m, cite_e, band, low),
    ]
    if visibility == "solid":
        strengths.append(
            _obs(
                f"The analysis suggests the swimmer stayed findable through most of this "
                f"{stroke} clip, so race-pace review of the middle segment is worthwhile.",
                cite_m,
                cite_e,
                "moderate",
                False,
            )
        )

    improvements: list[PriorityImprovement] = []
    for item in pack["improvements"][:3]:
        improvements.append(
            PriorityImprovement(
                observation=_obs(item["text"], cite_m, cite_e, band, low),
                drills=item["drills"][:2],
            )
        )

    if visibility == "limited":
        improvements = [
            PriorityImprovement(
                observation=_obs(
                    "The available frames may indicate splash, underwater phases, or camera "
                    "angle hid the body — clearer side video will unlock sharper stroke notes.",
                    cite_m,
                    cite_e,
                    "low",
                    True,
                ),
                drills=[
                    "Film one length from the side, camera steady, full body in frame.",
                    "Stand farther back and avoid zooming so the whole stroke cycle stays visible.",
                ],
            ),
            *improvements[:2],
        ]

    cov_txt = f"{coverage:.0%}" if coverage is not None else "n/a"
    det_txt = f"{int(detected)}" if detected is not None else "n/a"
    proc_txt = f"{int(processed)}" if processed is not None else "n/a"

    return CoachingReportBody(
        summary=(
            f"Coach breakdown for this {distance_bit}{stroke} clip: strengths, priority fixes, "
            f"drills, and next-race focus. Tracking visibility looked {visibility} "
            f"(coverage {cov_txt}; detections on {det_txt} of {proc_txt} analyzed frames)."
        ),
        strengths=strengths[:3],
        priority_improvements=improvements[:3],
        supporting_evidence=[
            f"Stroke context: {stroke}.",
            f"Swimmer tracking coverage: {cov_txt}.",
            "Tips are grounded in Elite tracking on this PC plus stroke-specific coaching standards.",
        ],
        race_recommendations=pack["next_race"][:4],
        limitations=[
            "Coaching used the fast local Elite coach path so your report is never empty.",
            "Estimates depend on video quality and camera angle.",
            "Splash and underwater segments can hide the body and lower certainty.",
        ],
        confidence_statement=(
            "Confidence follows how clearly the swimmer stayed visible in this clip. "
            "When visibility is limited, treat timing notes as practice guidance, not exact race splits."
        ),
        disclaimer=(
            "These tips depend on video quality and camera angle. "
            "They are practice guidance for training and racing, not medical advice."
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
    return aliases.get(s, s if s in {
        "butterfly", "freestyle", "backstroke", "breaststroke", "individual_medley"
    } else "unknown")


def _obs(
    text: str,
    metric_ids: list[str],
    event_ids: list[str],
    band: str,
    force_low_cue: bool,
) -> CoachingObservation:
    t = text.strip()
    if force_low_cue or band == "low":
        if not t.lower().startswith("the available frames may indicate"):
            t = "The available frames may indicate " + t[0].lower() + t[1:]
    elif band == "moderate":
        if "suggests" not in t.lower() and "may indicate" not in t.lower():
            t = "The analysis suggests " + t[0].lower() + t[1:]
    return CoachingObservation(
        text=t,
        confidence_band=band,  # type: ignore[arg-type]
        metric_ids=metric_ids,
        event_ids=event_ids,
    )


def _stroke_pack(stroke: str) -> dict:
    common_next = [
        "Pick one cue for the next race warm-up and repeat it on every length.",
        "Film the same race segment again from the side after the next practice block.",
    ]
    packs: dict[str, dict] = {
        "butterfly": {
            "strengths": [
                "Rhythm through the stroke cycle looks reviewable — keep pressing a connected kick and pull timing.",
                "Body-line moments in the clearer frames are worth copying: long, strong, and forward.",
            ],
            "improvements": [
                {
                    "text": "Prioritize a tighter body line into the breath so the hips do not sink when the head lifts.",
                    "drills": [
                        "3-3-3 butterfly: 3 strokes face down, 3 with breath, 3 face down.",
                        "Single-arm fly with a strong dolphin kick focus on hip drive.",
                    ],
                },
                {
                    "text": "Keep the second kick timed with hand entry so speed does not die between strokes.",
                    "drills": [
                        "Kickboard-free dolphin kick on stomach, hands at sides, 4 x 25.",
                        "Fly tempo ladder: easy / race / easy for 3 x 25.",
                    ],
                },
                {
                    "text": "Shorten the pause at the front of the stroke if the catch feels late in the clearer frames.",
                    "drills": [
                        "Right-arm / left-arm / both fly pattern for 4 x 25.",
                        "Fly with a snorkel to feel continuous forward pressure.",
                    ],
                },
            ],
            "next_race": [
                "Race cue: kick on entry, press the chest, breathe late and low.",
                "Take the first 15m underwater with tight dolphins, then break out into tempo you can hold.",
                *common_next,
            ],
        },
        "freestyle": {
            "strengths": [
                "Forward swim rhythm is clear enough to coach — protect a long, quiet head position.",
                "Side-view frames can show a usable catch window; keep that early pressure on race day.",
            ],
            "improvements": [
                {
                    "text": "Reduce side-to-side head movement so the hips stay higher and the kick stays thinner.",
                    "drills": [
                        "Snorkel freestyle focusing on a still forehead for 4 x 50.",
                        "6-kick switch freestyle to feel a long side balance.",
                    ],
                },
                {
                    "text": "Make the catch earlier and wider before the pull so each stroke travels farther.",
                    "drills": [
                        "Scull into freestyle catch for 4 x 25.",
                        "Fist / open-hand freestyle to feel early pressure.",
                    ],
                },
                {
                    "text": "Hold a steadier kick tempo through the middle of the race so speed does not fade.",
                    "drills": [
                        "12.5m sprint kick + 12.5m easy swim for 8 rounds.",
                        "Descend 4 x 50 free focusing on kick count consistency.",
                    ],
                },
            ],
            "next_race": [
                "Race cue: quiet head, early catch, kick that does not stop in the third 25.",
                "Breakout: tight streamline, then accelerate into your race stroke rate.",
                *common_next,
            ],
        },
        "backstroke": {
            "strengths": [
                "Body position looks coachable from the clearer frames — keep the hips high and the kick continuous.",
                "Arm timing windows are visible enough to rehearse a steady tempo.",
            ],
            "improvements": [
                {
                    "text": "Keep the kick smaller and steadier so the hips do not bounce when the arms accelerate.",
                    "drills": [
                        "Back kick on your back with arms at sides for 4 x 25.",
                        "12.5m underwater dolphin + breakout into backstroke tempo.",
                    ],
                },
                {
                    "text": "Enter cleaner above the shoulder so the catch starts earlier in each stroke.",
                    "drills": [
                        "Single-arm backstroke with the opposite arm at the side.",
                        "Backstroke with a tempo trainer on a controlled rate.",
                    ],
                },
            ],
            "next_race": [
                "Race cue: hips up, kick steady, enter above the shoulder and accelerate the finish.",
                "Protect underwater speed off each wall before settling into stroke rate.",
                *common_next,
            ],
        },
        "breaststroke": {
            "strengths": [
                "Timing of pull-breathe-kick can be reviewed from the clearer frames — keep the glide honest, not long.",
                "Forward line after the kick is a strength to protect when fatigue hits.",
            ],
            "improvements": [
                {
                    "text": "Shoot to a tighter streamline after the kick so the glide stays fast instead of flat.",
                    "drills": [
                        "2-kick / 1-pull breaststroke focusing on a long shoot.",
                        "Breaststroke with a snorkel to feel a quiet head and fast hands forward.",
                    ],
                },
                {
                    "text": "Accelerate the hands forward after the breath so the next pull starts on time.",
                    "drills": [
                        "Breaststroke pull with a flutter-kick emphasis on fast recovery.",
                        "3 strokes fast / 3 strokes easy timing ladder for 4 x 25.",
                    ],
                },
            ],
            "next_race": [
                "Race cue: pull, breathe, kick, shoot — no pause before the hands go forward.",
                "Off the wall: strong pullout, then break into race timing you can hold.",
                *common_next,
            ],
        },
    }
    default = {
        "strengths": [
            "The swimmer track is clear enough for a useful race review of body line and timing.",
            "Clearer frames show moments worth repeating: long line, steady rhythm, forward intent.",
        ],
        "improvements": [
            {
                "text": "Film the next clip from the true side so stroke phases stay visible start to finish.",
                "drills": [
                    "One length easy focusing on a long body line.",
                    "Race-pace 25s with a single technique cue only.",
                ],
            },
            {
                "text": "Choose one timing cue for the next race and ignore everything else under pressure.",
                "drills": [
                    "3 x 25 build: easy / strong / race with the same cue.",
                    "Broken 50s: 25 race + 10s rest + 25 race, same cue both lengths.",
                ],
            },
        ],
        "next_race": [
            "Race cue: one technical focus only — write it on your hand if needed.",
            "Warm up the exact race segment you just filmed before you step up.",
            *common_next,
        ],
    }
    return packs.get(stroke, default)

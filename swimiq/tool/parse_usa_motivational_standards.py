#!/usr/bin/env python3
"""Parse USA Swimming 2024-2028 Age Group Motivational Standards PDF to JSON."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import pdfplumber

VERSION_ID = "2024-2028"
VERSION_LABEL = "2024-2028 USA Swimming Motivational Standards"
LEVELS_GIRLS = ["B", "BB", "A", "AA", "AAA", "AAAA"]
LEVELS_BOYS = ["AAAA", "AAA", "AA", "A", "BB", "B"]

STROKE_MAP = {
    "FR": "Freestyle",
    "BK": "Backstroke",
    "BR": "Breaststroke",
    "FL": "Butterfly",
    "IM": "IM",
    "FR-R": "Free Relay",
    "MED-R": "Medley Relay",
}

TIME_RE = re.compile(r"(\d+:\d+(?:\.\d+)?|\d+(?:\.\d+)?)\s*\*?")
EVENT_RE = re.compile(
    r"(\d+)\s+(FR|BK|BR|FL|IM|FR-R|MED-R)\s+(SCY|SCM|LCM)"
)
AGE_GROUP_RE = re.compile(
    r"^(\d{1,2}\s*&\s*under|\d{1,2}-\d{1,2})\s+Girls\s+Event\s+"
    r"(\d{1,2}\s*&\s*under|\d{1,2}-\d{1,2})\s+Boys\s*$"
)


def parse_time(value: str) -> float:
    value = value.strip().rstrip("*").strip()
    if ":" in value:
        parts = value.split(":")
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
    return float(value)


def extract_times(segment: str) -> list[float]:
    return [parse_time(match.group(1)) for match in TIME_RE.finditer(segment)]


def normalize_age_group(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def build_event_record(
    *,
    age_group: str,
    gender: str,
    distance: int,
    stroke_code: str,
    course: str,
    times: list[float],
    levels: list[str],
) -> dict:
    cuts: dict[str, float] = {}
    for level, seconds in zip(levels, times):
        cuts[level] = round(seconds, 2)
    return {
        "version": VERSION_ID,
        "age_group": age_group,
        "gender": gender,
        "course": course,
        "distance": distance,
        "stroke": STROKE_MAP[stroke_code],
        "event": f"{distance} {STROKE_MAP[stroke_code]} {course}",
        "cuts": cuts,
    }


def parse_pdf(pdf_path: Path) -> list[dict]:
    records: list[dict] = []
    current_course: str | None = None
    current_age_group: str | None = None

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            for raw_line in text.splitlines():
                line = raw_line.strip()
                if not line or line.startswith("USA Swimming"):
                    continue
                if line.startswith("8/"):
                    continue
                if line.startswith("B BB A AA"):
                    continue

                if line in {"SCY", "SCM", "LCM"}:
                    current_course = line
                    continue

                age_match = re.match(
                    r"^(\d{1,2}\s*&\s*under|\d{1,2}-\d{1,2})\s+Girls\s+Event",
                    line,
                )
                if age_match:
                    current_age_group = normalize_age_group(age_match.group(1))
                    continue

                event_match = EVENT_RE.search(line)
                if not event_match:
                    continue

                if current_age_group is None:
                    continue

                distance = int(event_match.group(1))
                stroke_code = event_match.group(2)
                course = event_match.group(3)

                left = line[: event_match.start()].strip()
                right = line[event_match.end() :].strip()

                girls_times = extract_times(left)
                boys_times = extract_times(right)

                if len(girls_times) == 6:
                    records.append(
                        build_event_record(
                            age_group=current_age_group,
                            gender="Girls",
                            distance=distance,
                            stroke_code=stroke_code,
                            course=course,
                            times=girls_times,
                            levels=LEVELS_GIRLS,
                        )
                    )
                if len(boys_times) == 6:
                    records.append(
                        build_event_record(
                            age_group=current_age_group,
                            gender="Boys",
                            distance=distance,
                            stroke_code=stroke_code,
                            course=course,
                            times=boys_times,
                            levels=LEVELS_BOYS,
                        )
                    )

    return dedupe_records(records)


def dedupe_records(records: list[dict]) -> list[dict]:
    seen: set[tuple] = set()
    unique: list[dict] = []
    for record in records:
        key = (
            record["age_group"],
            record["gender"],
            record["course"],
            record["distance"],
            record["stroke"],
        )
        if key in seen:
            continue
        seen.add(key)
        unique.append(record)
    return unique


def flatten_records(records: list[dict]) -> list[dict]:
    flat: list[dict] = []
    for record in records:
        for level, seconds in record["cuts"].items():
            flat.append(
                {
                    "age_group": record["age_group"],
                    "gender": record["gender"],
                    "stroke": record["stroke"],
                    "distance": record["distance"],
                    "course": record["course"],
                    "standard_level": level,
                    "time_seconds": seconds,
                }
            )
    return flat


def main() -> int:
    pdf_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "2028-motivational-standards-age-group.pdf"
    )
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
        "assets/data/usa_motivational_standards_2024_2028.json"
    )

    records = parse_pdf(pdf_path)
    payload = {
        "version_id": VERSION_ID,
        "version_label": VERSION_LABEL,
        "source": "USA Swimming 2024-2028 Motivational Standards (Age Group)",
        "effective_through": 2028,
        "generated_from": pdf_path.name,
        "event_count": len(records),
        "events": records,
        "flat_standards": flatten_records(records),
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Wrote {len(records)} events / {len(payload['flat_standards'])} cuts -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

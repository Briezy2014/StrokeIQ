#!/usr/bin/env python3
"""Import USA Swimming motivational standards from the official PDF.

Usage:
  python scripts/import_motivational_standards.py \\
    --pdf path/to/2024-2028-motivational-standards.pdf \\
    --output data/motivational_standards.json

  python scripts/import_motivational_standards.py \\
    --pdf path/to/standards.pdf \\
    --supabase-url $SUPABASE_URL \\
    --supabase-key $SUPABASE_SERVICE_ROLE_KEY

The importer is reusable for future USA Swimming quad updates.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

DEFAULT_VERSION = "2024-2028 USA Swimming Motivational Standards"

LEVEL_COLUMNS = ("B", "BB", "A", "AA", "AAA", "AAAA")


@dataclass(frozen=True)
class MotivationalStandardRow:
    age_group: str
    gender: str
    course: str
    event: str
    b_time: float
    bb_time: float
    a_time: float
    aa_time: float
    aaa_time: float
    aaaa_time: float
    version: str = DEFAULT_VERSION

    def dedupe_key(self) -> tuple[str, str, str, str, str, str]:
        return (
            self.version,
            self.age_group,
            self.gender,
            self.course,
            self.event,
        )


def swim_time_to_seconds(time_text: str) -> float:
    """Convert swim time text to seconds."""
    text = time_text.strip()
    if not text:
        raise ValueError("Empty time value")

    if ":" in text:
        minutes, seconds = text.split(":", 1)
        return round((int(minutes) * 60) + float(seconds), 2)

    return round(float(text), 2)


def normalize_age_group(value: str) -> str:
    cleaned = value.strip()
    replacements = {
        "10 & under": "10 & Under",
        "10 and under": "10 & Under",
        "10&under": "10 & Under",
        "11-12": "11-12",
        "13-14": "13-14",
        "15-16": "15-16",
        "17-18": "17-18",
    }
    key = cleaned.lower().replace("  ", " ")
    return replacements.get(key, cleaned)


def normalize_gender(value: str) -> str:
    cleaned = value.strip().lower()
    if cleaned in {"girls", "girl", "female", "f"}:
        return "F"
    if cleaned in {"boys", "boy", "male", "m"}:
        return "M"
    raise ValueError(f"Unknown gender label: {value}")


def normalize_course(value: str) -> str:
    cleaned = value.strip().upper()
    if cleaned in {"SCY", "SCM", "LCM"}:
        return cleaned
    raise ValueError(f"Unknown course: {value}")


def normalize_event(value: str) -> str:
    text = re.sub(r"\s+", " ", value.strip())
    text = text.replace(" Y ", " ").replace(" L ", " ")
    text = text.replace("Free", "Freestyle")
    text = text.replace("Back", "Backstroke")
    text = text.replace("Breast", "Breaststroke")
    text = text.replace("Fly", "Butterfly")
    text = text.replace("IM", "Individual Medley")
    return text


def parse_pdf(pdf_path: Path, version: str) -> list[MotivationalStandardRow]:
    try:
        import pdfplumber
    except ImportError as exc:
        raise SystemExit(
            "pdfplumber is required. Install with: pip install pdfplumber"
        ) from exc

    rows: list[MotivationalStandardRow] = []
    current_age_group: str | None = None
    current_gender: str | None = None
    current_course: str | None = None

    age_group_pattern = re.compile(r"(10\s*&\s*under|11-12|13-14|15-16|17-18)", re.I)
    gender_pattern = re.compile(r"\b(girls?|boys?|female|male)\b", re.I)
    course_pattern = re.compile(r"\b(SCY|SCM|LCM)\b", re.I)

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            for line in text.splitlines():
                age_match = age_group_pattern.search(line)
                if age_match:
                    current_age_group = normalize_age_group(age_match.group(1))

                gender_match = gender_pattern.search(line)
                if gender_match:
                    current_gender = normalize_gender(gender_match.group(1))

                course_match = course_pattern.search(line)
                if course_match:
                    current_course = normalize_course(course_match.group(1))

            tables = page.extract_tables() or []
            for table in tables:
                if not table or len(table) < 2:
                    continue

                header = [str(cell or "").strip().upper() for cell in table[0]]
                if "EVENT" not in header[0].upper() and "EVENT" not in " ".join(header).upper():
                    continue

                level_indexes = {}
                for level in LEVEL_COLUMNS:
                    for index, column in enumerate(header):
                        if column.replace(" ", "") == level:
                            level_indexes[level] = index
                            break

                if len(level_indexes) != len(LEVEL_COLUMNS):
                    continue

                if not all([current_age_group, current_gender, current_course]):
                    continue

                for raw_row in table[1:]:
                    if not raw_row or not raw_row[0]:
                        continue

                    event = normalize_event(str(raw_row[0]))
                    if not event or event.lower() == "event":
                        continue

                    try:
                        times = {
                            level: swim_time_to_seconds(str(raw_row[index]))
                            for level, index in level_indexes.items()
                        }
                    except (ValueError, IndexError, TypeError):
                        continue

                    rows.append(
                        MotivationalStandardRow(
                            age_group=current_age_group,
                            gender=current_gender,
                            course=current_course,
                            event=event,
                            b_time=times["B"],
                            bb_time=times["BB"],
                            a_time=times["A"],
                            aa_time=times["AA"],
                            aaa_time=times["AAA"],
                            aaaa_time=times["AAAA"],
                            version=version,
                        )
                    )

    return dedupe_rows(rows)


def dedupe_rows(rows: list[MotivationalStandardRow]) -> list[MotivationalStandardRow]:
    unique: dict[tuple[str, str, str, str, str, str], MotivationalStandardRow] = {}
    for row in rows:
        unique[row.dedupe_key()] = row
    return list(unique.values())


def write_json(rows: list[MotivationalStandardRow], output_path: Path) -> None:
    payload = [
        {
            "age_group": row.age_group,
            "gender": row.gender,
            "course": row.course,
            "event": row.event,
            "b_time": row.b_time,
            "bb_time": row.bb_time,
            "a_time": row.a_time,
            "aa_time": row.aa_time,
            "aaa_time": row.aaa_time,
            "aaaa_time": row.aaaa_time,
            "version": row.version,
        }
        for row in rows
    ]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, indent=2))


def upload_supabase(
    rows: list[MotivationalStandardRow],
    supabase_url: str,
    supabase_key: str,
    version: str,
) -> None:
    from supabase import create_client

    client = create_client(supabase_url, supabase_key)

    client.table("motivational_standards").delete().eq("version", version).execute()

    batch_size = 500
    payload = [asdict(row) for row in rows]
    for start in range(0, len(payload), batch_size):
        chunk = payload[start : start + batch_size]
        client.table("motivational_standards").insert(chunk).execute()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", required=True, type=Path, help="Official standards PDF")
    parser.add_argument("--version", default=DEFAULT_VERSION)
    parser.add_argument("--output", type=Path, help="Optional JSON export path")
    parser.add_argument("--supabase-url", help="Supabase project URL")
    parser.add_argument("--supabase-key", help="Supabase service role key")

    args = parser.parse_args()

    if not args.pdf.exists():
        print(f"PDF not found: {args.pdf}", file=sys.stderr)
        return 1

    rows = parse_pdf(args.pdf, version=args.version)
    if not rows:
        print(
            "No standards extracted. Verify the PDF format or update the parser.",
            file=sys.stderr,
        )
        return 1

    rows = dedupe_rows(rows)
    print(f"Extracted {len(rows)} unique standard rows for version: {args.version}")

    if args.output:
        write_json(rows, args.output)
        print(f"Wrote {args.output}")

    if args.supabase_url and args.supabase_key:
        upload_supabase(rows, args.supabase_url, args.supabase_key, args.version)
        print("Uploaded standards to Supabase")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

def swim_time_to_seconds(time_text: str) -> float:
    """
    Convert swim time text into seconds.

import pandas as pd


def swim_time_to_seconds(time_text: str) -> float:
    """
    Convert swim time text into seconds.
    Accepts:
    - 35.43
    - 1:24.32
    - 5:31.43
    """
    time_text = str(time_text).strip()

    if not time_text:
        raise ValueError("Time is required.")

    if ":" in time_text:
        parts = time_text.split(":")
        if len(parts) != 2:
            raise ValueError("Use M:SS.hh format.")

        minutes, seconds = parts
        return round((int(minutes) * 60) + float(seconds), 2)

    return round(float(time_text), 2)


def seconds_to_swim_time(seconds) -> str:
    """Convert seconds into swim-time format."""
    try:
        seconds = float(seconds)
        minutes = int(seconds // 60)
        remaining = seconds % 60

        if minutes > 0:
            return f"{minutes}:{remaining:05.2f}"

        return f"{remaining:.2f}"
    except Exception:
        return ""


def get_personal_bests(race_logs: pd.DataFrame) -> pd.DataFrame:
    """Return best swim by stroke, distance, and course."""
    required_columns = {"stroke", "distance", "course", "time_seconds", "date"}

    if race_logs.empty or not required_columns.issubset(race_logs.columns):
        return pd.DataFrame()

    clean_logs = race_logs.copy()
    clean_logs["time_seconds"] = pd.to_numeric(
        clean_logs["time_seconds"],
        errors="coerce",
    )
    clean_logs = clean_logs.dropna(subset=["time_seconds"])

    if clean_logs.empty:
        return pd.DataFrame()

    personal_bests = (
        clean_logs.sort_values("time_seconds")
        .groupby(["stroke", "distance", "course"], as_index=False)
        .first()
    )

    personal_bests["Best Time"] = personal_bests["time_seconds"].apply(
        seconds_to_swim_time
    )

    return personal_bests


def is_new_personal_best(
    previous_logs: pd.DataFrame,
    stroke: str,
    distance: int,
    course: str,
    time_seconds: float,
) -> bool:
    """Check whether a swim is a new personal best."""
    required_columns = {"stroke", "distance", "course", "time_seconds"}

    if previous_logs.empty or not required_columns.issubset(previous_logs.columns):
        return True

    clean_logs = previous_logs.copy()
    clean_logs["time_seconds"] = pd.to_numeric(
        clean_logs["time_seconds"],
        errors="coerce",
    )
    clean_logs = clean_logs.dropna(subset=["time_seconds"])

    matching_swims = clean_logs[
        (clean_logs["stroke"] == stroke)
        & (clean_logs["distance"] == int(distance))
        & (clean_logs["course"] == course)
    ]

    if matching_swims.empty:
        return True

    previous_best = matching_swims["time_seconds"].min()
    return float(time_seconds) < float(previous_best)


def calculate_swimiq_score(race_logs: pd.DataFrame, goals: pd.DataFrame) -> int:
    """
    Version 2 SwimIQ Score.
    Simple and explainable:
    - Starts at 500 once the swimmer has logs
    - Adds points for sessions, goals, and PBs
    - Caps at 1000
    """
    if race_logs.empty:
        return 0

    total_sessions = len(race_logs)
    total_goals = 0 if goals.empty else len(goals)
    total_pbs = len(get_personal_bests(race_logs))

    score = 500
    score += total_sessions * 5
    score += total_goals * 20
    score += total_pbs * 25

    return min(score, 1000)


def safe_metric_time(df: pd.DataFrame, column: str, metric: str) -> str:
    """Return formatted best or average time."""
    if df.empty or column not in df.columns:
        return "—"

    values = pd.to_numeric(df[column], errors="coerce").dropna()

    if values.empty:
        return "—"

    if metric == "min":
        return seconds_to_swim_time(values.min())

    if metric == "mean":
        return seconds_to_swim_time(values.mean())

    return "—"


def add_formatted_time_column(
    df: pd.DataFrame,
    source_column: str,
    new_column: str,
) -> pd.DataFrame:
    """Return a DataFrame copy with a formatted swim-time column."""
    display_df = df.copy()

    if source_column in display_df.columns:
        display_df[new_column] = display_df[source_column].apply(seconds_to_swim_time)

    return display_df


def normalize_name(name: str) -> str:
    """Clean swimmer name/code."""
    return name.strip()
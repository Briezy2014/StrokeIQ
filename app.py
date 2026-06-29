from datetime import date
from pathlib import Path
import base64
from xxlimited import new

import pandas as pd
import plotly.express as px
import streamlit as st
from supabase import create_client


# ============================================================
# SwimIQ Version 2: Athlete Performance
# Built in the Water. Driven by Possibility.
# ============================================================

st.set_page_config(
    page_title="SwimIQ Version 2: Athlete Performance",
    page_icon="🏊‍♀️",
    layout="wide",
)


# ============================================================
# Supabase connection
# ============================================================

SUPABASE_URL = st.secrets["SUPABASE_URL"]
SUPABASE_KEY = st.secrets["SUPABASE_KEY"]

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# ============================================================
# Helper functions
# ============================================================

def normalize_name(name: str) -> str:
    """Clean swimmer name/code."""
    return name.strip()


def load_table(table_name: str, swimmer: str | None = None) -> pd.DataFrame:
    """Load a Supabase table into a pandas DataFrame."""
    try:
        query = supabase.table(table_name).select("*")
        if swimmer:
            query = query.eq("swimmer", swimmer)
        response = query.execute()
        return pd.DataFrame(response.data)
    except Exception:
        return pd.DataFrame()


def insert_row(table_name: str, row: dict):
    """Insert one row into Supabase."""
    return supabase.table(table_name).insert(row).execute()


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


# ============================================================
# Header
# ============================================================

LOGO_PATH = Path("assets/swimiq_logo.png")

st.markdown(
    """
    <style>
        .tagline {
            text-align: center;
            color: #0B5CAD;
            font-size: 30px;
            font-weight: 700;
            margin-top: 8px;
        }

        .founder {
            text-align: center;
            color: #222222;
            font-size: 22px;
            margin-top: -8px;
            margin-bottom: 25px;
        }

        .section-note {
            font-size: 15px;
            color: #555555;
        }
    </style>
    """,
    unsafe_allow_html=True,
)

if LOGO_PATH.exists():
    logo_base64 = base64.b64encode(LOGO_PATH.read_bytes()).decode()

    st.markdown(
        f"""
        <div style="text-align: center; width: 100%; margin: 0 auto;">
            <img src="data:image/png;base64,{logo_base64}" style="width: 700px; max-width: 90%;">
        </div>
        """,
        unsafe_allow_html=True,
    )

st.markdown(
    """
    <div class="tagline">Built in the Water. Driven by Possibility.</div>
    <div class="founder">Founded by Aspyn Briez</div>
    <hr>
    """,
    unsafe_allow_html=True,
)

st.info("Welcome to SwimIQ Version 2 Beta. Built in the Water. Driven by Possibility.")
st.caption("SwimIQ Version 2: Athlete Performance Edition")


# ============================================================
# Swimmer start screen
# ============================================================

if "active_swimmer" not in st.session_state:
    st.session_state.active_swimmer = ""

with st.container():
    swimmer_input = st.text_input(
        "Enter swimmer name or code",
        placeholder="Example: Emma12, JackFish, Aspyn",
        value=st.session_state.active_swimmer,
    )

    start_button = st.button("Start SwimIQ")

    if start_button:
        clean_name = normalize_name(swimmer_input)

        if clean_name:
            st.session_state.active_swimmer = clean_name
            st.rerun()
        else:
            st.warning("Please enter a swimmer name or code first.")

if not st.session_state.active_swimmer:
    st.stop()

active_swimmer = st.session_state.active_swimmer

st.success(f"Current swimmer: {active_swimmer}")

if st.button("Switch swimmer"):
    st.session_state.active_swimmer = ""
    st.rerun()


# ============================================================
# Load swimmer data
# ============================================================

race_logs = load_table("race_logs", active_swimmer)
goals = load_table("goals", active_swimmer)
meet_results = load_table("meet_results", active_swimmer)
# ============================================================
# Tabs
# ============================================================

tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs(
    [
        "📊 Dashboard",
        "🏆 Personal Bests",
        "➕ Add Swim Session",
        "🎯 Goals",
        "🏁 Meet Results",
        "👤 Athlete Passport",
    ]
)


# ============================================================
# Dashboard
# ============================================================

with tab1:
    st.subheader("Swimmer Dashboard")

    if race_logs.empty:
        st.warning("No swim sessions yet. Add a swim session to start building the dashboard.")
    else:
        dashboard_logs = race_logs.copy()

        if "date" in dashboard_logs.columns:
            dashboard_logs["date"] = pd.to_datetime(
                dashboard_logs["date"],
                errors="coerce",
            )

        swim_iq_score = calculate_swimiq_score(dashboard_logs, goals)
        total_sessions = len(dashboard_logs)
        total_personal_bests = len(get_personal_bests(dashboard_logs))
        active_goals = 0 if goals.empty else len(goals)

        col1, col2, col3, col4 = st.columns(4)
        col1.metric("SwimIQ Score", swim_iq_score)
        col2.metric("Total Sessions", total_sessions)
        col3.metric("Personal Bests", total_personal_bests)
        col4.metric("Active Goals", active_goals)

        col5, col6 = st.columns(2)
        col5.metric(
            "Best Time",
            safe_metric_time(dashboard_logs, "time_seconds", "min"),
        )
        col6.metric(
            "Average Time",
            safe_metric_time(dashboard_logs, "time_seconds", "mean"),
        )

        display_logs = add_formatted_time_column(
            dashboard_logs,
            source_column="time_seconds",
            new_column="formatted_time",
        )

        st.dataframe(display_logs, use_container_width=True)

        if {"date", "time_seconds", "stroke"}.issubset(dashboard_logs.columns):
            chart_logs = dashboard_logs.dropna(
                subset=["date", "time_seconds"]
            ).sort_values("date")

            if not chart_logs.empty:
                fig = px.line(
                    chart_logs,
                    x="date",
                    y="time_seconds",
                    color="stroke",
                    markers=True,
                    title="Time Progress",
                )

                st.plotly_chart(fig, use_container_width=True)


# ============================================================
# Personal Bests
# ============================================================

with tab2:
    st.subheader("Personal Bests")

    personal_bests = get_personal_bests(race_logs)

    if personal_bests.empty:
        st.warning("No personal bests yet. Add swim sessions to unlock this page.")
    else:
        st.dataframe(
            personal_bests[
                [
                    "stroke",
                    "distance",
                    "course",
                    "Best Time",
                    "date",
                ]
            ],
            use_container_width=True,
        )
        # ============================================================
# Add Swim Session
# ============================================================

with tab3:
    st.subheader("Add Swim Session")

    st.markdown(
        '<div class="section-note">Enter times like 35.43, 1:24.32, or 5:31.43.</div>',
        unsafe_allow_html=True,
    )

    with st.form("add_swim_session"):
        stroke = st.selectbox(
            "Stroke",
            ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"],
        )

        distance = st.number_input("Distance", min_value=25, step=25)

        course = st.selectbox(
            "Course",
            ["SCY", "SCM", "LCM"],
        )

        time_text = st.text_input(
            "Time",
            placeholder="Example: 35.43 or 1:24.32",
        )

        notes = st.text_area(
            "Notes optional",
            placeholder="Optional: stroke count, splits, race notes, how the swim felt, etc.",
        )

        session_date = st.date_input("Date", value=date.today())

        submitted = st.form_submit_button("Save Swim Session")

        if submitted:
            try:
                time_seconds = swim_time_to_seconds(time_text)

                new_personal_best = is_new_personal_best(
                    previous_logs=race_logs,
                    stroke=stroke,
                    distance=int(distance),
                    course=course,
                    time_seconds=time_seconds,
                )

                row = {
                    "date": str(session_date),
                    "swimmer": active_swimmer,
                    "event": f"{int(distance)} {stroke}",
                    "distance": int(distance),
                    "stroke": stroke,
                    "course": course,
                    "time_seconds": float(time_seconds),
                    "notes": notes,
                }

                insert_row("race_logs", row)

                if new_personal_best:
                    st.success("🔥 New Personal Best!")
                else:
                    st.success("Swim session saved.")

            except ValueError:
                st.error("Please enter time like 35.43, 1:24.32, or 5:31.43.")
            except Exception as e:
                st.error(f"Could not save session: {e}")


# ============================================================
# Goals
# ============================================================

with tab4:
    st.subheader("Swimmer Goals")

    with st.form("add_goal"):
        goal_stroke = st.selectbox(
            "Goal Stroke",
            ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"],
        )

        goal_distance = st.number_input("Goal Distance", min_value=25, step=25)

        target_time_text = st.text_input(
            "Target Time",
            placeholder="Example: 35.43 or 1:24.32",
        )

        goal_course = st.selectbox("Goal Course", ["SCY", "SCM", "LCM"])

        target_date = st.date_input("Target Date", value=date.today())

        submitted_goal = st.form_submit_button("Save Goal")

        if submitted_goal:
            try:
                target_time_s = swim_time_to_seconds(target_time_text)

                row = {
    "swimmer_name": active_swimmer,
    "event": f"{int(goal_distance)} {goal_stroke}",
    "current_time": None,
    "goal_time": float(target_time_s),
    "course": goal_course,
    "target_date": str(target_date),
}

                insert_row("goals", row)

                st.success("Goal saved.")

            except ValueError:
                st.error("Please enter target time like 35.43, 1:24.32, or 5:31.43.")
            except Exception as e:
                st.error(f"Could not save goal: {e}")

    st.divider()

    if goals.empty:
        st.warning("No goals yet.")
    else:
        display_goals = add_formatted_time_column(
            goals,
            source_column="goal_time",
            new_column="formatted_goal_time",
        )

        st.dataframe(display_goals, use_container_width=True)


# ============================================================
# Meet Results
# ============================================================

with tab5:
    st.subheader("Meet Results")

    with st.form("add_meet_result"):
        meet_name = st.text_input("Meet Name")

        meet_date = st.date_input("Meet Date", value=date.today())

        event_name = st.text_input(
            "Event",
            placeholder="Example: 100 Butterfly",
        )

        result_time_text = st.text_input(
            "Result Time",
            placeholder="Example: 35.43 or 1:24.32",
        )

        result_course = st.selectbox("Result Course", ["SCY", "SCM", "LCM"])

        submitted_result = st.form_submit_button("Save Meet Result")

        if submitted_result:
            try:
                result_time_s = swim_time_to_seconds(result_time_text)

                row = {
                    "swimmer_name": active_swimmer,
                    "meet_name": meet_name,
                    "meet_date": str(meet_date),
                    "event": event_name,
                    "swim_time": float(result_time_s),
                    "course": result_course,
                }

                insert_row("meet_results", row)

                st.success("Meet result saved.")

            except ValueError:
                st.error("Please enter result time like 35.43, 1:24.32, or 5:31.43.")

            except Exception as e:
                st.error(f"Could not save meet result: {e}")

    st.divider()

    if meet_results.empty:
        st.warning("No meet results yet.")
    else:
        display_results = add_formatted_time_column(
            meet_results,
            source_column="time_s",
            new_column="formatted_time",
        )

        st.dataframe(display_results, use_container_width=True)
# ============================================================
# Athlete Passport
# ============================================================
# ============================================================
# Athlete Passport
# ============================================================

with tab6:
    try:
        profile_response = (
            supabase.table("swimmers")
            .select("*")
            .eq("swimmer_name", active_swimmer)
            .execute()
        )
        profile_data = profile_response.data
    except Exception:
        profile_data = []

    existing_profile = profile_data[0] if profile_data else {}

    def get_profile_value(field_name, fallback="Not added yet"):
        value = existing_profile.get(field_name)
        return value if value not in [None, ""] else fallback

    def select_index(options, current_value, default_index=0):
        if current_value in options:
            return options.index(current_value)
        return default_index

    display_name = (
        existing_profile.get("preferred_name")
        or f"{existing_profile.get('first_name', '')} {existing_profile.get('last_name', '')}".strip()
        or active_swimmer
    )

    athlete_team = get_profile_value("team")
    athlete_coach = get_profile_value("coach_name")
    athlete_primary_stroke = get_profile_value("primary_stroke")
    athlete_secondary_stroke = get_profile_value("secondary_stroke")
    athlete_favorite_event = get_profile_value("favorite_event")
    athlete_graduation_year = get_profile_value("graduation_year")
    usa_swimming_id = get_profile_value("usa_swimming_id")

    total_goals = 0 if goals.empty else len(goals)
    total_sessions = 0 if race_logs.empty else len(race_logs)
    total_meets = 0 if meet_results.empty else len(meet_results)

    if not race_logs.empty and {"stroke", "distance", "course", "time_seconds"}.issubset(race_logs.columns):
        pb_logs = race_logs.copy()
        pb_logs["time_seconds"] = pd.to_numeric(pb_logs["time_seconds"], errors="coerce")
        pb_logs = pb_logs.dropna(subset=["time_seconds"])

        total_pbs = (
            pb_logs.sort_values("time_seconds")
            .groupby(["stroke", "distance", "course"], as_index=False)
            .first()
            .shape[0]
        )
    else:
        total_pbs = 0
        # -----------------------------
    # Athlete Passport UI
    # -----------------------------

    existing_birthday = existing_profile.get("birthday")
    if existing_birthday:
        try:
            birthday_value = pd.to_datetime(existing_birthday).date()
        except Exception:
            birthday_value = date(2012, 1, 1)
    else:
        birthday_value = date(2012, 1, 1)

    try:
        today = date.today()
        age_years = today.year - birthday_value.year - (
            (today.month, today.day) < (birthday_value.month, birthday_value.day)
        )
        age_label = f"{age_years} years old"
        birthday_label = birthday_value.strftime("%m/%d/%Y")
    except Exception:
        age_label = "Not added yet"
        birthday_label = "Not added yet"

    athlete_school = get_profile_value("school")
    athlete_notes_display = get_profile_value(
        "athlete_notes",
        "No athlete notes added yet.",
    )

    if athlete_favorite_event != "Not added yet":
        current_focus = athlete_favorite_event
    elif athlete_primary_stroke != "Not added yet":
        current_focus = athlete_primary_stroke
    else:
        current_focus = "Add focus event"

    st.markdown(
        """
        <style>
            .passport-shell {
                background: #F3FAFF;
                border-radius: 28px;
                padding: 26px;
                margin-bottom: 24px;
                border: 1px solid #D7EEFF;
            }

            .passport-hero-clean {
                background: linear-gradient(135deg, #009CFF 0%, #38B6FF 58%, #EAF8FF 100%);
                border-radius: 30px;
                padding: 42px 34px;
                text-align: center;
                color: white;
                box-shadow: 0px 10px 30px rgba(0, 156, 255, 0.26);
                border: 1px solid rgba(255,255,255,0.45);
            }

            .passport-avatar-clean {
                width: 112px;
                height: 112px;
                border-radius: 999px;
                background: rgba(255,255,255,0.96);
                color: #009CFF;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 48px;
                margin: 0 auto 18px auto;
                box-shadow: 0px 8px 24px rgba(0,0,0,0.18);
            }

            .passport-eyebrow {
                font-size: 13px;
                letter-spacing: 3px;
                font-weight: 900;
                text-transform: uppercase;
                opacity: 0.95;
                margin-bottom: 10px;
            }

            .passport-name-clean {
                font-size: 46px;
                font-weight: 950;
                line-height: 1.05;
                margin-bottom: 8px;
            }

            .passport-sub-clean {
                font-size: 18px;
                font-weight: 700;
                opacity: 0.96;
                margin-bottom: 6px;
            }

            .passport-small-clean {
                font-size: 15px;
                font-weight: 600;
                opacity: 0.92;
            }

            .passport-section-title {
                font-size: 23px;
                font-weight: 900;
                color: #0077C8;
                margin-top: 24px;
                margin-bottom: 12px;
            }

            .status-card {
                background: #FFFFFF;
                border-radius: 22px;
                padding: 22px;
                border: 1px solid #DDEEFF;
                box-shadow: 0px 5px 18px rgba(0, 75, 135, 0.08);
                min-height: 132px;
                margin-bottom: 14px;
            }

            .status-label {
                font-size: 12px;
                letter-spacing: 1.4px;
                text-transform: uppercase;
                font-weight: 900;
                color: #5C7894;
                margin-bottom: 8px;
            }

            .status-value {
                font-size: 28px;
                font-weight: 950;
                color: #0B2D4D;
                line-height: 1.08;
                margin-bottom: 6px;
            }

            .status-note {
                font-size: 14px;
                font-weight: 650;
                color: #5F7082;
                line-height: 1.35;
            }

            .detail-card {
                background: #FFFFFF;
                border-radius: 22px;
                padding: 24px;
                border: 1px solid #DDEEFF;
                box-shadow: 0px 5px 18px rgba(0, 75, 135, 0.07);
                margin-bottom: 16px;
            }

            .detail-title {
                font-size: 18px;
                font-weight: 950;
                color: #0077C8;
                margin-bottom: 16px;
            }

            .detail-row {
                display: flex;
                justify-content: space-between;
                gap: 16px;
                border-bottom: 1px solid #EEF6FC;
                padding: 9px 0;
            }

            .detail-row:last-child {
                border-bottom: none;
            }

            .detail-label {
                color: #61788F;
                font-weight: 800;
                font-size: 14px;
            }

            .detail-value {
                color: #0B2D4D;
                font-weight: 850;
                font-size: 14px;
                text-align: right;
            }

            .future-panel {
                background: linear-gradient(135deg, #EAF8FF, #FFFFFF);
                border: 1px dashed #66C7FF;
                border-radius: 24px;
                padding: 22px;
                margin-top: 18px;
                margin-bottom: 18px;
                color: #0B2D4D;
            }

            .future-title {
                font-size: 19px;
                font-weight: 950;
                color: #0077C8;
                margin-bottom: 10px;
            }

            .future-text {
                font-size: 15px;
                line-height: 1.75;
                font-weight: 650;
            }

            .edit-panel {
                background: #FFFFFF;
                border-radius: 24px;
                padding: 24px;
                border: 1px solid #DDEEFF;
                box-shadow: 0px 5px 18px rgba(0, 75, 135, 0.07);
                margin-top: 12px;
            }
        </style>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        f"""
        <div class="passport-shell">
            <div class="passport-hero-clean">
                <div class="passport-avatar-clean">🏊‍♀️</div>
                <div class="passport-eyebrow">Athlete Passport™</div>
                <div class="passport-name-clean">{display_name}</div>
                <div class="passport-sub-clean">{athlete_team}</div>
                <div class="passport-small-clean">
                    Coach: {athlete_coach} · {athlete_primary_stroke} Specialist · Class of {athlete_graduation_year}
                </div>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        '<div class="passport-section-title">Athlete Status</div>',
        unsafe_allow_html=True,
    )

    status1, status2, status3 = st.columns(3)

    with status1:
        st.markdown(
            """
            <div class="status-card">
                <div class="status-label">SwimIQ Score™</div>
                <div class="status-value">Coming Soon</div>
                <div class="status-note">A proprietary athlete score built from improvement, consistency, goals, and performance.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with status2:
        st.markdown(
            f"""
            <div class="status-card">
                <div class="status-label">Current Focus</div>
                <div class="status-value">{current_focus}</div>
                <div class="status-note">This will become the center of the athlete's active training block.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with status3:
        st.markdown(
            """
            <div class="status-card">
                <div class="status-label">Highest Achievement</div>
                <div class="status-value">Coming Soon</div>
                <div class="status-note">Future home for cuts, championships, standards, and verified milestones.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    status4, status5, status6 = st.columns(3)

    with status4:
        st.markdown(
            """
            <div class="status-card">
                <div class="status-label">Next Meet</div>
                <div class="status-value">Coming Soon</div>
                <div class="status-note">Meet countdown, events, and race plan will appear here.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with status5:
        st.markdown(
            """
            <div class="status-card">
                <div class="status-label">IMX / IMR</div>
                <div class="status-value">Coming Soon</div>
                <div class="status-note">USA Swimming IMX tracking can be added after core race data is stronger.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with status6:
        st.markdown(
            """
            <div class="status-card">
                <div class="status-label">Readiness</div>
                <div class="status-value">Coming Soon</div>
                <div class="status-note">Future recovery score using sleep, wellness, training load, and athlete check-ins.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.markdown(
        '<div class="passport-section-title">Athlete Details</div>',
        unsafe_allow_html=True,
    )

    detail_col1, detail_col2 = st.columns(2)

    with detail_col1:
        st.markdown(
            f"""
            <div class="detail-card">
                <div class="detail-title">Athlete Identity</div>

                <div class="detail-row">
                    <div class="detail-label">Display Name</div>
                    <div class="detail-value">{display_name}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Birthday</div>
                    <div class="detail-value">{birthday_label}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Age</div>
                    <div class="detail-value">{age_label}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Graduation Year</div>
                    <div class="detail-value">{athlete_graduation_year}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">School</div>
                    <div class="detail-value">{athlete_school}</div>
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with detail_col2:
        st.markdown(
            f"""
            <div class="detail-card">
                <div class="detail-title">USA Swimming Profile</div>

                <div class="detail-row">
                    <div class="detail-label">USA Swimming ID</div>
                    <div class="detail-value">{usa_swimming_id}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Club Team</div>
                    <div class="detail-value">{athlete_team}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Coach</div>
                    <div class="detail-value">{athlete_coach}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Primary Stroke</div>
                    <div class="detail-value">{athlete_primary_stroke}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Secondary Stroke</div>
                    <div class="detail-value">{athlete_secondary_stroke}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Favorite Event</div>
                    <div class="detail-value">{athlete_favorite_event}</div>
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    detail_col3, detail_col4 = st.columns(2)

    with detail_col3:
        st.markdown(
            f"""
            <div class="detail-card">
                <div class="detail-title">SwimIQ Activity</div>

                <div class="detail-row">
                    <div class="detail-label">Current Goals</div>
                    <div class="detail-value">{total_goals}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Personal Bests</div>
                    <div class="detail-value">{total_pbs}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Training Sessions</div>
                    <div class="detail-value">{total_sessions}</div>
                </div>

                <div class="detail-row">
                    <div class="detail-label">Meet Results</div>
                    <div class="detail-value">{total_meets}</div>
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with detail_col4:
        st.markdown(
            f"""
            <div class="detail-card">
                <div class="detail-title">Athlete Notes</div>
                <div style="color:#0B2D4D; font-weight:700; line-height:1.55;">
                    {athlete_notes_display}
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.markdown(
        """
        <div class="future-panel">
            <div class="future-title">Coming Soon to Athlete Passport™</div>
            <div class="future-text">
                🤖 AI Coach &nbsp;&nbsp;|&nbsp;&nbsp;
                🧬 SwimDNA™ &nbsp;&nbsp;|&nbsp;&nbsp;
                🎓 Recruiting Center &nbsp;&nbsp;|&nbsp;&nbsp;
                🎥 Video Lab &nbsp;&nbsp;|&nbsp;&nbsp;
                🏁 Race Intelligence™ &nbsp;&nbsp;|&nbsp;&nbsp;
                📊 USA Swimming Standards
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.divider()

    st.markdown(
        '<div class="passport-section-title">Edit Athlete Passport</div>',
        unsafe_allow_html=True,
    )

    st.markdown(
        '<div class="edit-panel">',
        unsafe_allow_html=True,
    )

    with st.form("athlete_passport_form"):
        first_name = st.text_input(
            "First Name",
            value=existing_profile.get("first_name", ""),
        )

        last_name = st.text_input(
            "Last Name",
            value=existing_profile.get("last_name", ""),
        )

        preferred_name = st.text_input(
            "Preferred Name",
            value=existing_profile.get("preferred_name", active_swimmer),
        )

        birthday = st.date_input(
            "Birthday",
            value=birthday_value,
            min_value=date(2000, 1, 1),
            max_value=date.today(),
            format="MM/DD/YYYY",
        )

        graduation_year = st.number_input(
            "Graduation Year",
            min_value=2026,
            max_value=2045,
            value=int(existing_profile.get("graduation_year") or 2032),
            step=1,
        )

        club_team = st.text_input(
            "Club Team",
            value=existing_profile.get("team", ""),
        )

        coach_name = st.text_input(
            "Coach",
            value=existing_profile.get("coach_name", ""),
        )

        stroke_options = ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"]

        primary_stroke = st.selectbox(
            "Primary Stroke",
            stroke_options,
            index=select_index(
                stroke_options,
                existing_profile.get("primary_stroke"),
                3,
            ),
        )

        secondary_stroke = st.selectbox(
            "Secondary Stroke",
            stroke_options,
            index=select_index(
                stroke_options,
                existing_profile.get("secondary_stroke"),
                0,
            ),
        )

        favorite_event = st.text_input(
            "Favorite Event",
            value=existing_profile.get("favorite_event", ""),
            placeholder="Example: 100 Butterfly",
        )

        usa_swimming_id_form = st.text_input(
            "USA Swimming ID",
            value=existing_profile.get("usa_swimming_id", ""),
        )

        school = st.text_input(
            "School",
            value=existing_profile.get("school", ""),
        )

        athlete_notes = st.text_area(
            "Athlete Notes",
            value=existing_profile.get("athlete_notes", ""),
            placeholder="Example: Strong butterfly swimmer, working on back-half speed.",
        )

        submitted_passport = st.form_submit_button("Save Athlete Passport")

        if submitted_passport:
            try:
                passport_row = {
                    "swimmer_name": active_swimmer,
                    "first_name": first_name,
                    "last_name": last_name,
                    "preferred_name": preferred_name,
                    "birthday": str(birthday),
                    "graduation_year": int(graduation_year),
                    "team": club_team,
                    "coach_name": coach_name,
                    "primary_stroke": primary_stroke,
                    "secondary_stroke": secondary_stroke,
                    "favorite_event": favorite_event,
                    "usa_swimming_id": usa_swimming_id_form,
                    "school": school,
                    "athlete_notes": athlete_notes,
                }

                if existing_profile.get("id"):
                    supabase.table("swimmers").update(passport_row).eq(
                        "id",
                        existing_profile["id"],
                    ).execute()
                else:
                    supabase.table("swimmers").insert(passport_row).execute()

                st.success("Athlete Passport saved.")

            except Exception as e:
                st.error(f"Could not save Athlete Passport: {e}")

    st.markdown(
        '</div>',
        unsafe_allow_html=True,
    )
# ============================================================
   # Footer
# ============================================================

st.markdown("---")

st.markdown(
    """
    <div style="text-align:center; font-size:14px;">
        © 2026 SwimIQ · Founded by Aspyn Briez
    </div>
    """,
    unsafe_allow_html=True,
)
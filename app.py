from datetime import date
from pathlib import Path
import base64

import pandas as pd
import plotly.express as px
import streamlit as st
from supabase import create_client


st.set_page_config(
    page_title="SwimIQ Version 2: Athlete Performance",
    page_icon="🏊‍♀️",
    layout="wide",
)

SUPABASE_URL = st.secrets["SUPABASE_URL"]
SUPABASE_KEY = st.secrets["SUPABASE_KEY"]

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# -----------------------------
# Helpers
# -----------------------------

def normalize_name(name: str) -> str:
    return name.strip()


def load_table(table_name: str, swimmer: str | None = None) -> pd.DataFrame:
    try:
        query = supabase.table(table_name).select("*")
        if swimmer:
            query = query.eq("swimmer", swimmer)
        response = query.execute()
        return pd.DataFrame(response.data)
    except Exception:
        return pd.DataFrame()


def insert_row(table_name: str, row: dict):
    return supabase.table(table_name).insert(row).execute()


def swim_time_to_seconds(time_text: str) -> float:
    time_text = time_text.strip()

    if ":" in time_text:
        minutes, seconds = time_text.split(":")
        return round((int(minutes) * 60) + float(seconds), 2)

    return round(float(time_text), 2)


def seconds_to_swim_time(seconds) -> str:
    try:
        seconds = float(seconds)
        minutes = int(seconds // 60)
        remaining = seconds % 60

        if minutes > 0:
            return f"{minutes}:{remaining:05.2f}"

        return f"{remaining:.2f}"
    except Exception:
        return ""


# -----------------------------
# Header
# -----------------------------

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


# -----------------------------
# Swimmer Start Screen
# -----------------------------

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


# -----------------------------
# Tabs
# -----------------------------

tab1, tab2, tab3, tab4, tab5 = st.tabs(
    ["📊 Dashboard", "🏆 Personal Bests", "➕ Add Swim Session", "🎯 Goals", "🏁 Meet Results"]
)


# -----------------------------
# Dashboard
# -----------------------------

with tab1:
    st.subheader("Swimmer Dashboard")

    race_logs = load_table("race_logs", active_swimmer)


    if race_logs.empty:
        st.warning("No swim sessions yet. Add a swim session to start building the dashboard.")
    else:
        race_logs["date"] = pd.to_datetime(race_logs["date"], errors="coerce")

        if "distance" in race_logs.columns and "time_seconds" in race_logs.columns:
            total_sessions = len(race_logs)
            best_time = race_logs["time_seconds"].min()
            avg_time = race_logs["time_seconds"].mean()

            col1, col2, col3 = st.columns(3)
            col1.metric("Total Sessions", total_sessions)
            col2.metric("Best Time", seconds_to_swim_time(best_time))
            col3.metric("Average Time", seconds_to_swim_time(avg_time))

        display_logs = race_logs.copy()

        if "time_seconds" in display_logs.columns:
            display_logs["formatted_time"] = display_logs["time_seconds"].apply(seconds_to_swim_time)

        st.dataframe(display_logs, use_container_width=True)

        if {"date", "time_seconds", "stroke"}.issubset(race_logs.columns):
            fig = px.line(
                race_logs.sort_values("date"),
                x="date",
                y="time_seconds",
                color="stroke",
                markers=True,
                title="Time Progress",
            )
            st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Personal Bests
# -----------------------------

with tab2:
    st.subheader("Personal Bests")

    race_logs = load_table("race_logs", active_swimmer)

    if race_logs.empty:
        st.warning("No swim sessions yet. Add swim sessions to unlock personal bests.")

    elif {"stroke", "distance", "course", "time_seconds", "date"}.issubset(race_logs.columns):

        pb_rows = (
            race_logs.sort_values("time_seconds")
            .groupby(["stroke", "distance", "course"], as_index=False)
            .first()
        )

        pb_rows["Best Time"] = pb_rows["time_seconds"].apply(seconds_to_swim_time)

        st.dataframe(
            pb_rows[
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

    else:
        st.warning("Personal Bests cannot be calculated yet.")


# -----------------------------
# Add Swim Session
# -----------------------------

# -----------------------------
# Add Swim Session
# -----------------------------

with tab3:
    st.subheader("Add Swim Session")

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
            placeholder="Optional: stroke count, race notes, splits, how the swim felt, etc.",
        )

        session_date = st.date_input("Date", value=date.today())

        submitted = st.form_submit_button("Save Swim Session")

       int(distance),
                    "stroke": stroke,
                    "course": course,
                    "time_seconds": float(time_seconds),
                    "notes": notes,
                }

                insert_row("race_logs", row)
                st.success("Swim session saved.")
                st.rerun()

            except ValueError:
                st.error("Please enter time like 35.43, 1:24.32, or 5:31.43.")
            except Exception as e:
                st.error(f"Could not save session: {e}")


# -----------------------------
# Goals
# -----------------------------

with tab4:
    st.subheader("Swimmer Goals")

    goals = load_table("goals", active_swimmer)

    with st.form("add_goal"):
        goal_stroke = st.selectbox(
            "Goal Stroke", if submitted:
            try:
                time_seconds = swim_time_to_seconds(time_text)

                row = {
                    "date": str(session_date),
                    "swimmer": active_swimmer,
                    "event": f"{int(distance)} {stroke}",
                    "distance": 
            ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"],
        )

        goal_distance = st.number_input("Goal Distance", min_value=25, step=25)

        target_time_text = st.text_input(
            "Target Time",
            placeholder="Example: 35.43 or 1:24.32",
        )

        course = st.selectbox("Goal Course", ["SCY", "SCM", "LCM"])
        target_date = st.date_input("Target Date", value=date.today())

        submitted_goal = st.form_submit_button("Save Goal")

        if submitted_goal:
            try:
                target_time_s = swim_time_to_seconds(target_time_text)

                row = {
                    "swimmer": active_swimmer,
                    "stroke": goal_stroke,
                    "distance_m": int(goal_distance),
                    "target_time_s": float(target_time_s),
                    "course": course,
                    "target_date": str(target_date),
                }

                insert_row("goals", row)
                st.success("Goal saved.")
                st.rerun()

            except ValueError:
                st.error("Please enter target time like 35.43, 1:24.32, or 5:31.43.")
            except Exception as e:
                st.error(f"Could not save goal: {e}")

    st.divider()

    if goals.empty:
        st.warning("No goals yet.")
    else:
        st.dataframe(goals, use_container_width=True)


# -----------------------------
# Meet Results
# -----------------------------

with tab5:
    st.subheader("Meet Results")

    meet_results = load_table("meet_results", active_swimmer)

    with st.form("add_meet_result"):
        meet_name = st.text_input("Meet Name")
        meet_date = st.date_input("Meet Date", value=date.today())
        event_name = st.text_input("Event", placeholder="Example: 100 Butterfly")

        result_time_text = st.text_input(
            "Result Time",
            placeholder="Example: 35.43 or 1:24.32",
        )

        result_course = st.selectbox("Result Course", ["SCY", "SCM", "LCM"])

        submitted_result = st.form_submit_button("Save Meet Result")

                if submitted:
            try:
                time_seconds = swim_time_to_seconds(time_text)

                previous_logs = load_table("race_logs", active_swimmer)

                is_personal_best = False

                if not previous_logs.empty and {
                    "stroke",
                    "distance",
                    "course",
                    "time_seconds",
                }.issubset(previous_logs.columns):
                    matching_swims = previous_logs[
                        (previous_logs["stroke"] == stroke)
                        & (previous_logs["distance"] == int(distance))
                        & (previous_logs["course"] == course)
                    ]

                    if matching_swims.empty:
                        is_personal_best = True
                    else:
                        previous_best = matching_swims["time_seconds"].min()
                        is_personal_best = time_seconds < previous_best
                else:
                    is_personal_best = True

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

                if is_personal_best:
                    st.success("🔥 New Personal Best!")
                else:
                    st.success("Swim session saved.")

                st.rerun()

            except ValueError:
                st.error("Please enter time like 35.43, 1:24.32, or 5:31.43.")
            except Exception as e:
                st.error(f"Could not save session: {e}")
    st.divider()

    if meet_results.empty:
        st.warning("No meet results yet.")
    else:
        st.dataframe(meet_results, use_container_width=True)


# -----------------------------
# Footer
# -----------------------------

st.markdown("---")
st.markdown(
    """
    <div style="text-align:center; font-size:14px;">
        © 2026 SwimIQ · Founded by Aspyn Briez
    </div>
    """,
    unsafe_allow_html=True,
)
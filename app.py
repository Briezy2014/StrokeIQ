from datetime import date

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


def calculate_dps(distance_m, stroke_count):
    if stroke_count and stroke_count > 0:
        return round(distance_m / stroke_count, 2)
    return 0


def calculate_stroke_rate(time_s, stroke_count):
    if time_s and time_s > 0:
        return round((stroke_count / time_s) * 60, 2)
    return 0
def swim_time_to_seconds(time_text: str) -> float:
    time_text = time_text.strip()

    if ":" in time_text:
        minutes, seconds = time_text.split(":")
        return round((int(minutes) * 60) + float(seconds), 2)

    return round(float(time_text), 2)

# -----------------------------
# -----------------------------
# -----------------------------
# Header
# -----------------------------
from pathlib import Path
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

LOGO_PATH = Path("assets/swimiq_logo.png")
logo_base64 = ""
if LOGO_PATH.exists():
    with open(LOGO_PATH, "rb") as logo_file:
        logo_base64 = base64.b64encode(logo_file.read()).decode()

if logo_base64:
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

st.info(
    "Welcome to SwimIQ Version 2 Beta. Built in the Water. Driven by Possibility."
    )
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

tab1, tab2, tab3, tab4 = st.tabs(
    ["📊 Dashboard", "➕ Add Swim Session", "🎯 Goals", "🏁 Meet Results"]
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

        if "distance_m" in race_logs.columns and "time_s" in race_logs.columns:
            total_sessions = len(race_logs)
            best_time = race_logs["time_s"].min()
            avg_time = race_logs["time_s"].mean()

            col1, col2, col3 = st.columns(3)
            col1.metric("Total Sessions", total_sessions)
            col2.metric("Best Time", f"{best_time:.2f} sec")
            col3.metric("Average Time", f"{avg_time:.2f} sec")

        if "stroke_count" in race_logs.columns:
            race_logs["dps"] = race_logs.apply(
                lambda row: calculate_dps(row.get("distance_m", 0), row.get("stroke_count", 0)),
                axis=1,
            )
            race_logs["stroke_rate"] = race_logs.apply(
                lambda row: calculate_stroke_rate(row.get("time_s", 0), row.get("stroke_count", 0)),
                axis=1,
            )

            col4, col5 = st.columns(2)
            col4.metric("Best DPS", f"{race_logs['dps'].max():.2f}")
            col5.metric("Avg Stroke Rate", f"{race_logs['stroke_rate'].mean():.2f}")

        st.dataframe(race_logs, use_container_width=True)

        if {"date", "time_s", "stroke"}.issubset(race_logs.columns):
            fig = px.line(
                race_logs.sort_values("date"),
                x="date",
                y="time_s",
                color="stroke",
                markers=True,
                title="Time Progress",
            )
            st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Add Swim Session
# -----------------------------

with tab2:
    st.subheader("Add Swim Session")

    with st.form("add_swim_session"):
        stroke = st.selectbox(
            "Stroke",
            ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"],
        )

        distance_m = st.number_input("Distance", min_value=25, step=25)
        course = st.selectbox(
            "Course",
            ["SCY", "SCM", "LCM"],
        )

        time_text = st.text_input(
    "Time",
    placeholder="Example: 35.43 or 1:24.32",
)
        stroke_count = st.number_input("Stroke count", min_value=0, step=1)
        session_date = st.date_input("Date", value=date.today())

        submitted = st.form_submit_button("Save Swim Session")

        if submitted:
            try:
                time_seconds = swim_time_to_seconds(time_text)

                row = {
                    "date": str(session_date),
                    "swimmer": active_swimmer,
                    "event": f"{int(distance_m)} {stroke}",
                    "distance": int(distance_m),
                    "stroke": stroke,
                    "course": course,
                    "time_seconds": float(time_seconds),
                    "stroke_count": int(stroke_count),
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

with tab3:
    st.subheader("Swimmer Goals")

    goals = load_table("goals", active_swimmer)

    with st.form("add_goal"):
        goal_stroke = st.selectbox(
            "Goal Stroke",
            ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM"],
        )

        goal_distance = st.number_input("Goal Distance", min_value=25, step=25)
        target_time_s = st.number_input("Target Time in Seconds", min_value=0.00, step=0.01)
        course = st.selectbox("Course", ["SCY", "SCM", "LCM"])
        target_date = st.date_input("Target Date", value=date.today())

        submitted_goal = st.form_submit_button("Save Goal")

        if submitted_goal:
            row = {
                "swimmer": active_swimmer,
                "stroke": goal_stroke,
                "distance_m": int(goal_distance),
                "target_time_s": float(target_time_s),
                "course": course,
                "target_date": str(target_date),
            }

            try:
                insert_row("goals", row)
                st.success("Goal saved.")
                st.rerun()
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

with tab4:
    st.subheader("Meet Results")

    meet_results = load_table("meet_results", active_swimmer)

    with st.form("add_meet_result"):
        meet_name = st.text_input("Meet Name")
        meet_date = st.date_input("Meet Date", value=date.today())
        event_name = st.text_input("Event", placeholder="Example: 100 Butterfly")
        result_time_s = st.number_input("Result Time in Seconds", min_value=0.00, step=0.01)
        result_course = st.selectbox("Result Course", ["SCY", "SCM", "LCM"])

        submitted_result = st.form_submit_button("Save Meet Result")

        if submitted_result:
            row = {
                "swimmer": active_swimmer,
                "meet_name": meet_name,
                "meet_date": str(meet_date),
                "event": event_name,
                "time_s": float(result_time_s),
                "course": result_course,
            }

            try:
                insert_row("meet_results", row)
                st.success("Meet result saved.")
                st.rerun()
            except Exception as e:
                st.error(f"Could not save meet result: {e}")

    st.divider()

    if meet_results.empty:
        st.warning("No meet results yet.")
    else:
        st.dataframe(meet_results, use_container_width=True)
        st.markdown("---")
st.markdown(
    """
    <div style="text-align:center; font-size:14px;">
        © 2026 SwimIQ · Founded by Aspyn Briez
    </div>
    """,
    unsafe_allow_html=True,
)
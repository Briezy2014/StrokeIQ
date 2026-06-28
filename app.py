from pathlib import Path
import base64

import streamlit as st

from database import load_table
from dashboard import render_dashboard_tab
from goals import render_goals_tab
from helpers import normalize_name
from meet_results import render_meet_results_tab
from personal_bests import render_personal_bests_tab
from swim_sessions import render_swim_sessions_tab
from swimmers import render_swimmer_profile


# ============================================================
# SwimIQ Version 2: Modular App
# Built in the Water. Driven by Possibility.
# ============================================================

st.set_page_config(
    page_title="SwimIQ Version 2: Athlete Performance",
    page_icon="🏊‍♀️",
    layout="wide",
)


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

race_logs = load_table("race_logs", active_swimmer, swimmer_column="swimmer")
goals = load_table("goals", active_swimmer, swimmer_column="swimmer_name")
meet_results = load_table(
    "meet_results",
    active_swimmer,
    swimmer_column="swimmer_name",
)
swimmer_profile = load_table(
    "swimmers",
    active_swimmer,
    swimmer_column="swimmer_name",
)


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
        "👤 Swimmer Profile",
    ]
)


with tab1:
    render_dashboard_tab(race_logs, goals)

with tab2:
    render_personal_bests_tab(race_logs)

with tab3:
    render_swim_sessions_tab(active_swimmer, race_logs)

with tab4:
    render_goals_tab(active_swimmer, goals)

with tab5:
    render_meet_results_tab(active_swimmer, meet_results)

with tab6:
    render_swimmer_profile(swimmer_profile)


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
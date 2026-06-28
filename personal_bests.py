import streamlit as st

from helpers import get_personal_bests


def render_personal_bests_tab(race_logs):
    """Render Personal Bests tab."""
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
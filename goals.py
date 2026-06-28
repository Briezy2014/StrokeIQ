from datetime import date

import streamlit as st

from database import insert_row
from helpers import add_formatted_time_column, swim_time_to_seconds


def render_goals_tab(active_swimmer, goals):
    """Render Goals tab."""
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
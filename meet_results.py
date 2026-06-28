from datetime import date

import streamlit as st

from database import insert_row
from helpers import add_formatted_time_column, swim_time_to_seconds


def render_meet_results_tab(active_swimmer, meet_results):
    """Render Meet Results tab."""

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

        result_course = st.selectbox(
            "Result Course",
            ["SCY", "SCM", "LCM"],
        )

        submitted_result = st.form_submit_button("Save Meet Result")

        if submitted_result:
            try:

                result_time_s = swim_time_to_seconds(result_time_text)

                row = {
                    "swimmer_name": active_swimmer,
                    "meet_name": meet_name,
                    "meet_date": str(meet_date),
                    "event": event_name,
                    "time_s": float(result_time_s),
                    "course": result_course,
                }

                insert_row("meet_results", row)

                st.success("Meet result saved.")

            except ValueError:
                st.error(
                    "Please enter result time like 35.43, 1:24.32, or 5:31.43."
                )

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

        st.dataframe(
            display_results,
            use_container_width=True,
        )
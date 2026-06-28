from datetime import date

import streamlit as st

from database import insert_row
from helpers import is_new_personal_best, swim_time_to_seconds


def render_swim_sessions_tab(active_swimmer, race_logs):
    """Render Add Swim Session tab."""
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
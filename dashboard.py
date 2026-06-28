import pandas as pd
import plotly.express as px
import streamlit as st

from helpers import (
    add_formatted_time_column,
    calculate_swimiq_score,
    get_personal_bests,
    safe_metric_time,
)


def render_dashboard_tab(race_logs, goals):
    """Render Dashboard tab."""
    st.subheader("Swimmer Dashboard")

    if race_logs.empty:
        st.warning("No swim sessions yet. Add a swim session to start building the dashboard.")
        return

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
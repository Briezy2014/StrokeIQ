"""StrokeIQ Swim Analytics Dashboard."""

from datetime import date
from pathlib import Path

import pandas as pd
import plotly.express as px
import streamlit as st
from supabase import create_client

DATA_PATH = Path("data/swim_data.csv")
RAW_COLUMNS = ["date", "swimmer", "stroke", "distance_m", "time_s", "stroke_count"]
SUPABASE_URL = st.secrets["SUPABASE_URL"]
SUPABASE_KEY = st.secrets["SUPABASE_KEY"]
supabase = create_client (SUPABASE_URL, SUPABASE_KEY)

def ensure_data_file() -> None:
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not DATA_PATH.exists():
        pd.DataFrame(columns=RAW_COLUMNS).to_csv(DATA_PATH, index=False)


def load_data() -> pd.DataFrame:
    response = supabase.table("race_logs").select("*").execute()
    df = pd.DataFrame(response.data)

    if df.empty:
        return pd.DataFrame(columns=RAW_COLUMNS)

    df = df.rename(columns={
    "distance": "distance_m",
    "time_seconds": "time_s",
})

    df["date"] = pd.to_datetime(df["date"]).dt.date
    df["stroke_rate"] = df["stroke_count"] / (df["time_s"] / 60)
    df["dps"] = df["distance_m"] / df["stroke_count"]
    df["time_per_100m"] = df["time_s"] / (df["distance_m"] / 100)

    return df


def append_entry(row: dict[str, object]) -> None:
        supabase_row = {
        "date": row["date"],
        "swimmer": row["swimmer"],
        "event": row["stroke"],
        "distance": row["distance_m"],
        "stroke": row["stroke"],
        "course": "SCY",
        "time_seconds": row["time_s"],
        "notes": f"Stroke count: {row['stroke_count']}",
    }
        supabase.table("race_logs").insert(supabase_row).execute()

    def build_personal_records(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame()

    records = (
        df.groupby(["swimmer", "stroke"]).agg(
            best_dps=("dps", "max"),
            best_stroke_rate=("stroke_rate", "max"),
            best_time_per_100m=("time_per_100m", "min"),
            best_distance=("distance_m", "max"),
        )
        .reset_index()
        .sort_values(["swimmer", "stroke"])
    )
    return records


def compute_weekly_improvement(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return pd.DataFrame()

    weekly = (
        df.assign(week=lambda x: pd.to_datetime(x["date"]).dt.to_period("W").apply(lambda p: p.start_time))
        .groupby("week")
        .agg(
            avg_dps=("dps", "mean"),
            avg_stroke_rate=("stroke_rate", "mean"),
            avg_time_per_100m=("time_per_100m", "mean"),
        )
        .sort_index()
    )
    if len(weekly) < 2:
        return weekly

    weekly["dps_change_pct"] = weekly["avg_dps"].pct_change() * 100
    weekly["stroke_rate_change_pct"] = weekly["avg_stroke_rate"].pct_change() * 100
    weekly["time_change_pct"] = weekly["avg_time_per_100m"].pct_change() * 100
    return weekly


def build_recommendations(df: pd.DataFrame) -> list[str]:
    if df.empty:
        return [
            "Add swim sessions to start seeing personalized recommendations.",
            "Use the form above to log distance, time, stroke count, and stroke style.",
        ]

    avg_dps = df["dps"].mean()
    avg_stroke_rate = df["stroke_rate"].mean()
    avg_time_100 = df["time_per_100m"].mean()
    avg_stroke_count = df["stroke_count"].mean()

    recommendations: list[str] = []
    if avg_dps < 1.8:
        recommendations.append(
            "Work on longer, more efficient strokes to raise your distance per stroke (DPS)."
        )
    else:
        recommendations.append("Your DPS is strong. Keep focusing on consistent stroke length.")

    if avg_stroke_rate > 36:
        recommendations.append(
            "Your stroke rate is high; try to swim with smoother technique to reduce wasted energy."
        )
    else:
        recommendations.append("Your stroke rate is in a comfortable range for endurance work.")

    if avg_time_100 > 70:
        recommendations.append(
            "Aim to lower your 100m pace by improving technique or increasing interval intensity."
        )

    if avg_stroke_count > 32:
        recommendations.append(
            "Reduce stroke count by lengthening each pull and maintaining better body position."
        )
    else:
        recommendations.append("Maintain your stroke economy and continue refining efficiency.")

    recommendations.append(
        "Track weekly progress and celebrate personal bests in DPS and stroke rate."
    )
    return recommendations


def render_dashboard(df: pd.DataFrame) -> None:
    st.header("Swim Performance Dashboard")

    if df.empty:
        st.info("No swim sessions have been logged yet. Use the form above to add a swim.")
        return

    stats = {
        "Total Sessions": len(df),
        "Average DPS": f"{df['dps'].mean():.2f}",
        "Average Stroke Rate": f"{df['stroke_rate'].mean():.1f}",
        "Best DPS": f"{df['dps'].max():.2f}",
    }

    cols = st.columns(4)
    for index, (column, value) in enumerate(stats.items()):
        cols[index].metric(column, value)

    with st.expander("Session data preview"):
        st.dataframe(df.sort_values(["date"], ascending=False).reset_index(drop=True))

    line_cols = st.columns(2)
    with line_cols[0]:
        fig_dps = px.line(
            df,
            x="date",
            y="dps",
            color="swimmer",
            markers=True,
            title="Distance Per Stroke (DPS) Trend",
        )
        st.plotly_chart(fig_dps, use_container_width=True)

    with line_cols[1]:
        fig_rate = px.line(
            df,
            x="date",
            y="stroke_rate",
            color="stroke",
            markers=True,
            title="Stroke Rate Trend",
        )
        st.plotly_chart(fig_rate, use_container_width=True)

    perf_cols = st.columns(2)
    with perf_cols[0]:
        fig_time = px.line(
            df,
            x="date",
            y="time_per_100m",
            color="swimmer",
            markers=True,
            title="Average 100m Pace",
        )
        st.plotly_chart(fig_time, use_container_width=True)

    with perf_cols[1]:
        fig_distance = px.bar(
            df,
            x="date",
            y="distance_m",
            color="stroke",
            title="Distance per Session",
        )
        st.plotly_chart(fig_distance, use_container_width=True)

    st.subheader("Personal Records")
    records = build_personal_records(df)
    st.dataframe(records)

    st.subheader("Weekly Improvements")
    weekly = compute_weekly_improvement(df)
    if weekly.empty or len(weekly) < 2:
        st.info("Add at least two weeks of swim data to see improvement percentages.")
        st.dataframe(weekly.reset_index())
    else:
        st.dataframe(weekly.reset_index())

    st.subheader("Recommendations")
    for rec in build_recommendations(df):
        st.markdown(f"- {rec}")


def main() -> None:
    st.set_page_config(page_title="StrokeIQ", page_icon="🏊", layout="wide")
    st.title("StrokeIQ Swim Analytics Dashboard")
    st.markdown(
        "Track swim sessions, compare performance over time, and discover efficiency insights for each stroke style."
    )

    with st.sidebar:
        st.header("Add Swim Session")
        with st.form("swim_entry_form"):
            swimmer = st.text_input("Swimmer name", value="Aspyn")
            stroke = st.selectbox("Stroke", ["Free", "Back", "Breast", "Fly"])
            distance_m = st.number_input("Distance (meters)", min_value=50, max_value=10000, value=1000, step=25)
            time_s = st.number_input("Time (seconds)", min_value=10, max_value=10000, value=600, step=5)
            stroke_count = st.number_input("Stroke count", min_value=10, max_value=2000, value=320, step=1)
            swim_date = st.date_input("Date", value=date.today())
            submitted = st.form_submit_button("Log session")

            if submitted:
                entry = {
                    "date": swim_date.isoformat(),
                    "swimmer": swimmer.strip() or "Aspyn",
                    "stroke": stroke,
                    "distance_m": int(distance_m),
                    "time_s": int(time_s),
                    "stroke_count": int(stroke_count),
                }
                append_entry(entry)
                st.success("Swim session logged successfully.")
                st.rerun()

    data = load_data()
    render_dashboard(data)


if __name__ == "__main__":
    main()

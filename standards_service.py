"""Supabase access layer for motivational standards."""

from __future__ import annotations

from typing import Any

import pandas as pd
import streamlit as st
from supabase import Client, create_client

DEFAULT_VERSION = "2024-2028 USA Swimming Motivational Standards"


def get_client() -> Client:
    return create_client(st.secrets["SUPABASE_URL"], st.secrets["SUPABASE_KEY"])


def load_standards(
    version: str = DEFAULT_VERSION,
    age_group: str | None = None,
    gender: str | None = None,
    course: str | None = None,
    event_query: str | None = None,
) -> pd.DataFrame:
    client = get_client()
    query = client.table("motivational_standards").select("*").eq("version", version)

    if age_group:
        query = query.eq("age_group", age_group)
    if gender:
        query = query.eq("gender", gender)
    if course:
        query = query.eq("course", course)
    if event_query:
        query = query.ilike("event", f"%{event_query}%")

    response = query.order("event").execute()
    return pd.DataFrame(response.data or [])


def fetch_standard_for_event(
    *,
    age_group: str,
    gender: str,
    course: str,
    event: str,
    version: str = DEFAULT_VERSION,
) -> dict[str, Any] | None:
    client = get_client()
    response = (
        client.table("motivational_standards")
        .select("*")
        .eq("version", version)
        .eq("age_group", age_group)
        .eq("gender", gender)
        .eq("course", course)
        .eq("event", event)
        .maybe_single()
        .execute()
    )
    return response.data


def standards_count(version: str = DEFAULT_VERSION) -> int:
    client = get_client()
    response = (
        client.table("motivational_standards")
        .select("id", count="exact")
        .eq("version", version)
        .execute()
    )
    return int(response.count or 0)

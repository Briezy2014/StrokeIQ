import pandas as pd
import streamlit as st
from supabase import create_client


SUPABASE_URL = st.secrets["SUPABASE_URL"]
SUPABASE_KEY = st.secrets["SUPABASE_KEY"]

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


def load_table(
    table_name: str,
    swimmer: str | None = None,
    swimmer_column: str = "swimmer",
) -> pd.DataFrame:
    """Load a Supabase table into a pandas DataFrame."""
    try:
        query = supabase.table(table_name).select("*")

        if swimmer:
            query = query.eq(swimmer_column, swimmer)

        response = query.execute()
        return pd.DataFrame(response.data)

    except Exception:
        return pd.DataFrame()


def insert_row(table_name: str, row: dict):
    """Insert one row into Supabase."""
    return supabase.table(table_name).insert(row).execute()
import streamlit as st


def render_swimmer_profile(swimmer_data):
    """Render swimmer profile section."""

    st.subheader("Swimmer Profile")

    if swimmer_data.empty:
        st.info("No swimmer profile found yet.")
        return

    st.dataframe(swimmer_data, use_container_width=True)
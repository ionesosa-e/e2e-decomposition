import plotly.express as px
import pandas as pd
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import read_csv_safe, find_col

MAX_BARS = 25  # cap for long bar charts



def load_and_merge_fanin_fanout(df_in: pd.DataFrame, df_out: pd.DataFrame) -> pd.DataFrame:
    """
    Load and merge Fan_In and Fan_Out dataframes.
    Returns a unified dataframe with columns: type, fanIn, fanOut
    """
    c_type_in = find_col(df_in, "type", contains="type", default=None) if not df_in.empty else None
    c_fanin = find_col(df_in, "fanIn", contains="fanin", default=None) if not df_in.empty else None
    c_type_out = find_col(df_out, "type", contains="type", default=None) if not df_out.empty else None
    c_fanout = find_col(df_out, "fanOut", contains="fanout", default=None) if not df_out.empty else None

    if c_type_in and c_fanin:
        a = df_in[[c_type_in, c_fanin]].copy()
        a.columns = ["type", "fanIn"]
    else:
        a = pd.DataFrame(columns=["type", "fanIn"])

    if c_type_out and c_fanout:
        b = df_out[[c_type_out, c_fanout]].copy()
        b.columns = ["type", "fanOut"]
    else:
        b = pd.DataFrame(columns=["type", "fanOut"])

    # Merge
    merged = pd.merge(a, b, on="type", how="outer").fillna(0)
    merged["fanIn"] = pd.to_numeric(merged["fanIn"], errors="coerce").fillna(0).astype(int)
    merged["fanOut"] = pd.to_numeric(merged["fanOut"], errors="coerce").fillna(0).astype(int)

    return merged




def create_top_fanin_bar(df: pd.DataFrame):
    """Create bar chart for top classes by Fan-In."""
    if df.empty:
        return None

    top_in = df.sort_values("fanIn", ascending=False).head(MAX_BARS)

    fig = px.bar(top_in, x="type", y="fanIn", text="fanIn",
                 title="Top classes by Fan-In",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, width=1200, height=550,
                      xaxis_title="class", yaxis_title="fan-in")
    return fig


def create_top_fanout_bar(df: pd.DataFrame):
    """Create bar chart for top classes by Fan-Out."""
    if df.empty:
        return None

    top_out = df.sort_values("fanOut", ascending=False).head(MAX_BARS)

    fig = px.bar(top_out, x="type", y="fanOut", text="fanOut",
                 title="Top classes by Fan-Out",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, width=1200, height=550,
                      xaxis_title="class", yaxis_title="fan-out")
    return fig


def create_fanin_vs_fanout_scatter(df: pd.DataFrame):
    """Create scatter plot for Fan-In vs Fan-Out."""
    if df.empty:
        return None

    df_work = df.copy()
    df_work["total"] = df_work["fanIn"] + df_work["fanOut"]

    fig = px.scatter(df_work, x="fanOut", y="fanIn", size="total",
                     hover_name="type",
                     title="Fan-In vs Fan-Out (size = fanIn + fanOut)")
    fig.update_layout(width=950, height=700, xaxis_title="fan-out", yaxis_title="fan-in")
    return fig


def create_fanin_distribution(df: pd.DataFrame):
    """Create histogram for distribution of Fan-In."""
    if df.empty:
        return None

    fig = px.histogram(df, x="fanIn", nbins=30,
                       title="Distribution of Fan-In",
                       color_discrete_sequence=["#636EFA"])
    fig.update_layout(width=800, height=450, xaxis_title="fan-in", yaxis_title="count")
    return fig


def create_fanout_distribution(df: pd.DataFrame):
    """Create histogram for distribution of Fan-Out."""
    if df.empty:
        return None

    fig = px.histogram(df, x="fanOut", nbins=30,
                       title="Distribution of Fan-Out",
                       color_discrete_sequence=["#EF553B"])
    fig.update_layout(width=800, height=450, xaxis_title="fan-out", yaxis_title="count")
    return fig


def create_ratio_bar(df: pd.DataFrame):
    """Create bar chart for top classes by Fan-In to Fan-Out ratio."""
    if df.empty:
        return None

    df_work = df.copy()
    df_work["ratio_in_out"] = df_work["fanIn"] / (df_work["fanOut"] + 1.0)
    top_ratio = df_work.sort_values("ratio_in_out", ascending=False).head(MAX_BARS)

    fig = px.bar(top_ratio, x="type", y="ratio_in_out", text="ratio_in_out",
                 title="Top classes by Fan-In to Fan-Out ratio",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(texttemplate='%{text:.2f}', textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, width=1200, height=550,
                      xaxis_title="class", yaxis_title="ratio (fan-in / (fan-out + 1))")
    return fig




def render_fan_in_fan_out(df_in: pd.DataFrame, df_out: pd.DataFrame):
    """Render all Fan-In / Fan-Out charts in Streamlit."""
    import streamlit as st

    merged = load_and_merge_fanin_fanout(df_in, df_out)

    if merged.empty:
        st.info("No data available for Fan-In / Fan-Out analysis. The CSV files may be missing or empty.")
        return

    st.markdown(f"**Total classes analyzed:** {len(merged)}")
    st.markdown(f"**Classes with Fan-In > 0:** {len(merged[merged['fanIn'] > 0])}")
    st.markdown(f"**Classes with Fan-Out > 0:** {len(merged[merged['fanOut'] > 0])}")

    st.subheader("1) Top Classes by Fan-In")
    fig = create_top_fanin_bar(merged)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.divider()

    st.subheader("2) Top Classes by Fan-Out")
    fig = create_top_fanout_bar(merged)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.divider()

    st.subheader("3) Fan-In vs Fan-Out (Scatter)")
    fig = create_fanin_vs_fanout_scatter(merged)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.divider()

    st.subheader("4) Distributions")

    col1, col2 = st.columns(2)

    with col1:
        st.markdown("**4A) Fan-In Distribution**")
        fig = create_fanin_distribution(merged)
        if fig:
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.markdown("**4B) Fan-Out Distribution**")
        fig = create_fanout_distribution(merged)
        if fig:
            st.plotly_chart(fig, use_container_width=True)

    st.divider()

    st.subheader("5) Ratio View (Fan-In / (Fan-Out + 1))")
    st.markdown("Classes with high ratio may be potential hotspots (many dependencies on them, few outgoing).")
    fig = create_ratio_bar(merged)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

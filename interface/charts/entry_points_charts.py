import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path
import sys

# Add parent directory to path to import helpers
sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import fillna_safe

def render_main_classes_charts(df: pd.DataFrame):
    """Render all charts for Main Classes analysis.

    Expected columns: mainClass, isStatic, visibility, signature
    """
    if df.empty:
        st.info("No data available for Main Classes analysis. The CSV file may be missing or empty.")
        return

    # Normalize column names to lowercase for easier access
    cols = {c.lower(): c for c in df.columns}
    c_main = cols.get("mainclass")
    c_static = cols.get("isstatic")
    c_vis = cols.get("visibility")
    c_sig = cols.get("signature")

    # Chart 1A: Visibility distribution
    if c_vis:
        st.subheader("1A) Visibility Distribution")
        vis_counts = fillna_safe(df[c_vis], "unknown").astype(str).value_counts().reset_index()
        vis_counts.columns = ["visibility", "count"]
        fig = px.bar(vis_counts, x="visibility", y="count",
                     title="main(String[]) visibility distribution", text_auto=True)
        fig.update_layout(width=900, height=420, xaxis_title="visibility", yaxis_title="count")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'visibility' not found — skipping visibility chart.")

    # Chart 1B: Static vs non-static
    if c_static:
        st.subheader("1B) Static vs Non-Static")
        stat = fillna_safe(df[c_static], False).map(lambda x: "static" if bool(x) else "non-static")
        stat_counts = stat.value_counts().reset_index()
        stat_counts.columns = ["kind", "count"]
        fig = px.pie(stat_counts, names="kind", values="count",
                     title="static vs non-static main methods", hole=0.35)
        fig.update_layout(width=700, height=450)
        fig.update_traces(textposition="outside")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'isStatic' not found — skipping static/non-static chart.")

    # Chart 1C: Top classes exposing main()
    if c_main:
        st.subheader("1C) Top Classes with main() Method")
        top_classes = df[c_main].astype(str).value_counts().reset_index()
        top_classes.columns = ["className", "count"]
        fig = px.bar(top_classes.head(30), x="className", y="count",
                     title="Classes with main() — Top 30", text_auto=True)
        fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                         xaxis_title="class", yaxis_title="count")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'mainClass' not found — skipping top classes chart.")

    # Chart 1D: Signature variants
    if c_sig:
        st.subheader("1D) Method Signature Variants")
        sig_counts = fillna_safe(df[c_sig], "unknown").astype(str).value_counts().reset_index()
        sig_counts.columns = ["signature", "count"]
        fig = px.bar(sig_counts.head(20), x="signature", y="count",
                     title="Main method signature variants (Top 20)", text_auto=True)
        fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                         xaxis_title="signature", yaxis_title="count")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'signature' not found — skipping signature chart.")

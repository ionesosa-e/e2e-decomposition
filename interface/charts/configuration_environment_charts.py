import plotly.express as px
import pandas as pd
from pathlib import Path
import sys 

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import labelize_na, ext_from_name, pick_col

def create_annotation_chart(df_cfg, c_ann):
    counts = labelize_na(df_cfg[c_ann]).value_counts().reset_index()
    counts.columns = ["annotationType", "count"]
    fig = px.pie(counts, names="annotationType", values="count", hole=0.35,
                    title="Configuration classes by annotation type")
    fig.update_layout(width=760, height=460)
    fig.update_traces(textposition="outside")
    return fig

def create_extension_chart(df_files, name_col, DEFAULT_BAR_COLOR):
    names = labelize_na(df_files[name_col])
    df_files["ext"] = names.map(ext_from_name)
    ext_counts = df_files["ext"].value_counts().reset_index()
    ext_counts.columns = ["extension", "count"]
    fig = px.bar(ext_counts, x="extension", y="count", text_auto=True,
                    title="Configuration files by extension",
                    color_discrete_sequence=DEFAULT_BAR_COLOR)
    fig.update_layout(width=820, height=440, xaxis_title="extension", yaxis_title="count")
    return fig

def create_flag_chart(df_flags, c_src):
    counts = labelize_na(df_flags[c_src]).value_counts().reset_index()
    counts.columns = ["source", "count"]
    fig = px.pie(counts, names="source", values="count", hole=0.35,
                    title="Feature-flag sources")
    fig.update_layout(width=720, height=420)
    fig.update_traces(textposition="outside")
    return fig

def create_injected_properties_chart(df_inj, c_type, DEFAULT_BAR_COLOR):
    counts = labelize_na(df_inj[c_type]).value_counts().reset_index()
    counts.columns = ["fieldType", "count"]
    fig = px.bar(counts.head(25), x="fieldType", y="count", text_auto=True,
                    title="Injected field types (Top 25)",
                    color_discrete_sequence=DEFAULT_BAR_COLOR)
    fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                        xaxis_title="fieldType", yaxis_title="count")
    return fig



def render_annotation_chart(df:pd.DataFrame):
    import streamlit as st

    if df.empty:
        st.info("No data available for Configuration Classes analysis. The CSV file may be missing or empty.")
        return

    c_ann = pick_col(df, ["annotationType","annotation","type"], kind=None)
    st.subheader("1A) Annotation Distribution")
    fig = create_annotation_chart(df, c_ann)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("No annotation column found — skipping annotation chart.")


def render_extension_chart(df: pd.DataFrame):
    import streamlit as st

    if df.empty:
        st.info("No data available for Configuration Files analysis. The CSV file may be missing or empty.")
        return

    # Find file name column
    name_col = None
    for cand in ["configurationFile.name","name","fileName","filename","path","configurationFile"]:
        candidates = [c for c in df.columns if c.lower() == cand.lower()]
        if candidates:
            name_col = candidates[0]
            break
    if name_col is None:
        name_col = pick_col(df, kind="text")

    st.subheader("2A) Configuration Files by Extension")
    if name_col:
        fig = create_extension_chart(df, name_col, ["#1f77b4"])
        if fig:
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No file extension data detected.")
    else:
        st.warning("Could not detect file-name column — skipping chart.")


def render_feature_flag_chart(df:pd.DataFrame):
    import streamlit as st

    if df.empty:
        st.info("No data available for Feature Flags analysis. The CSV file may be missing or empty.")
        return

    c_src = pick_col(df, ["source","origin"], kind=None)
    st.subheader("3A) Feature Flag Sources")
    if c_src:
        fig = create_flag_chart(df, c_src)
        if fig:
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No source data detected.")
    else:
        st.warning("No 'source' column found — skipping chart.")


def render_injected_properties_chart(df:pd.DataFrame):
    import streamlit as st

    if df.empty:
        st.info("No data available for Injected Properties analysis. The CSV file may be missing or empty.")
        return

    c_type = pick_col(df, ["fieldType","type","signature"], kind=None)
    st.subheader("4A) Injected Field Types (Top 25)")
    if c_type:
        fig = create_injected_properties_chart(df, c_type, ["#1f77b4"])
        if fig:
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No field type data detected.")
    else:
        st.warning("No field type column found — skipping chart.")
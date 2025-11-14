import plotly.express as px
import pandas as pd
from pathlib import Path
from urllib.parse import urlparse
import sys

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import labelize_na, find_col

MAX_BARS = 25



def create_sdk_treemap(df: pd.DataFrame, c_grp: str, c_art: str):
    """Create treemap for external SDK usage (Group → Artifact)."""
    usage = df.groupby([c_grp, c_art]).size().reset_index(name="count")
    usage[c_grp] = labelize_na(usage[c_grp])
    usage[c_art] = labelize_na(usage[c_art])

    fig = px.treemap(usage, path=[c_grp, c_art], values="count",
                     title="External SDK usage (Group → Artifact)")
    fig.update_layout(width=1000, height=650)
    return fig


def create_top_artifacts_bar(df: pd.DataFrame, c_grp: str, c_art: str):
    """Create bar chart for top external SDK artifacts by usage."""
    usage = df.groupby([c_grp, c_art]).size().reset_index(name="count")
    usage[c_grp] = labelize_na(usage[c_grp])
    usage[c_art] = labelize_na(usage[c_art])

    top_art = (usage.groupby(c_art)["count"].sum()
                    .reset_index()
                    .sort_values("count", ascending=False)
                    .head(MAX_BARS))

    fig = px.bar(top_art, x=c_art, y="count", text="count",
                 title="Top external SDK artifacts by usage",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-30, width=1100, height=550,
                      xaxis_title="artifact", yaxis_title="usage (class references)")
    return fig


def create_groups_bar(df: pd.DataFrame, c_grp: str, c_art: str):
    """Create bar chart for external SDK usage by group."""
    usage = df.groupby([c_grp, c_art]).size().reset_index(name="count")
    usage[c_grp] = labelize_na(usage[c_grp])

    by_group = usage.groupby(c_grp)["count"].sum().reset_index(name="usage")
    top_groups = by_group.sort_values("usage", ascending=False).head(MAX_BARS)

    fig = px.bar(top_groups, x=c_grp, y="usage", text="usage",
                 title="External SDK usage by group",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-30, width=1100, height=550,
                      xaxis_title="group", yaxis_title="usage (class references)")
    return fig




def parse_url_components(df: pd.DataFrame, c_ep: str):
    """Helper to parse URLs and extract scheme and host."""
    work = df[[c_ep]].copy()
    work.columns = ["endpoint"]

    def parse_host(url):
        try:
            u = urlparse(str(url))
            return (u.scheme or "N/A", (u.netloc or "").split("@")[-1])  # strip userinfo if present
        except Exception:
            return ("N/A", "N/A")

    sch, host = zip(*[parse_host(v) for v in work["endpoint"]])
    work["scheme"] = sch
    work["host"] = [h.split(":")[0] for h in host]  # strip port if present

    return work


def create_top_hosts_bar(df: pd.DataFrame, c_ep: str):
    """Create bar chart for top hardcoded URL hosts."""
    work = parse_url_components(df, c_ep)

    top_hosts = (work.groupby("host").size()
                     .reset_index(name="count")
                     .sort_values("count", ascending=False)
                     .head(MAX_BARS))

    fig = px.bar(top_hosts, x="host", y="count", text="count",
                 title="Top hardcoded URL hosts",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-30, width=1100, height=550,
                      xaxis_title="host", yaxis_title="count")
    return fig


def create_host_class_treemap(df: pd.DataFrame, c_ep: str, c_cls: str):
    """Create treemap for Host → Declaring Class (limited to top hosts)."""
    work = parse_url_components(df, c_ep)

    top_hosts = (work.groupby("host").size()
                     .reset_index(name="count")
                     .sort_values("count", ascending=False)
                     .head(12))
    top_host_set = set(top_hosts["host"])

    sub = df[df[c_ep].isin(work[work["host"].isin(top_host_set)]["endpoint"])].copy()
    sub = sub.merge(work[["endpoint", "host"]], left_on=c_ep, right_on="endpoint", how="left")
    sub[c_cls] = sub[c_cls].astype(str)
    sub["host"] = sub["host"].astype(str)
    sub["value"] = 1

    fig = px.treemap(sub, path=["host", c_cls], values="value",
                     title="Hardcoded URLs — Host → Declaring Class (Top hosts)")
    fig.update_layout(width=1100, height=700)
    return fig


def create_scheme_share_donut(df: pd.DataFrame, c_ep: str):
    """Create donut chart for scheme share (http vs https)."""
    work = parse_url_components(df, c_ep)

    scheme_share = work.groupby("scheme").size().reset_index(name="count")

    fig = px.pie(scheme_share, names="scheme", values="count", hole=0.35,
                 title="Scheme share (http vs https)")
    fig.update_traces(textposition="inside")
    fig.update_layout(width=700, height=550)
    return fig




def render_external_sdks(df: pd.DataFrame):
    """Render External SDKs charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for External SDKs analysis. The CSV file may be missing or empty.")
        return

    c_grp = find_col(df, "artifactGroup", "group", contains="group", default=None)
    c_art = find_col(df, "artifactName", "name", contains="name", default=None)

    if not c_grp or not c_art:
        st.warning("Missing required columns (group, artifact) for External SDKs analysis.")
        return

    st.subheader("1A) External SDK Usage (Group → Artifact)")
    fig = create_sdk_treemap(df, c_grp, c_art)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1B) Top External SDK Artifacts by Usage")
    fig = create_top_artifacts_bar(df, c_grp, c_art)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1C) External SDK Usage by Group")
    fig = create_groups_bar(df, c_grp, c_art)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_hardcoded_urls(df: pd.DataFrame):
    """Render Hardcoded URLs charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Hardcoded URLs analysis. The CSV file may be missing or empty.")
        return

    c_ep = find_col(df, "endpoint", contains="endpoint", default=None)
    c_cls = find_col(df, "declaringClass", contains="class", default=None)
    c_fld = find_col(df, "fieldName", contains="field", default=None)

    if not c_ep:
        st.warning("Missing required 'endpoint' column for Hardcoded URLs analysis.")
        return

    st.subheader("2A) Top Hardcoded URL Hosts")
    fig = create_top_hosts_bar(df, c_ep)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    if c_cls:
        st.subheader("2B) Hardcoded URLs — Host → Declaring Class")
        fig = create_host_class_treemap(df, c_ep, c_cls)
        if fig:
            st.plotly_chart(fig, use_container_width=True)

    st.subheader("2C) Scheme Share (HTTP vs HTTPS)")
    fig = create_scheme_share_donut(df, c_ep)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    # 2D) Compact table
    st.subheader("2D) Hardcoded URLs — Sample Data")
    cols = [c for c in [c_ep, c_cls, c_fld] if c]
    st.dataframe(df[cols].head(100), use_container_width=True)

import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import labelize_na, find_col

MAX_BARS = 25  # cap for long bar charts

# ============================================================================
# SECTION 1: CIRCULAR DEPENDENCIES
# ============================================================================

def create_circular_pairs_bar(df: pd.DataFrame, c_p1: str, c_p2: str, c_fwd: str, c_bwd: str):
    """Create bar chart for top circular package pairs by total dependencies."""
    tmp = df[[c_p1, c_p2, c_fwd, c_bwd]].copy()
    tmp.columns = ["package1", "package2", "fwd", "bwd"]
    tmp["fwd"] = pd.to_numeric(tmp["fwd"], errors="coerce").fillna(0)
    tmp["bwd"] = pd.to_numeric(tmp["bwd"], errors="coerce").fillna(0)
    tmp["total"] = tmp["fwd"] + tmp["bwd"]
    top_pairs = tmp.sort_values("total", ascending=False).head(MAX_BARS)

    fig = px.bar(top_pairs,
                 x=top_pairs["package1"] + " ⇄ " + top_pairs["package2"],
                 y="total", text="total",
                 title="Top circular package pairs by total dependencies",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, width=1200, height=550,
                      xaxis_title="package pair", yaxis_title="total dependencies")
    return fig


def create_circular_heatmap(df: pd.DataFrame, c_p1: str, c_p2: str, c_fwd: str, c_bwd: str):
    """Create heatmap for circular dependencies (top pairs)."""
    tmp = df[[c_p1, c_p2, c_fwd, c_bwd]].copy()
    tmp.columns = ["package1", "package2", "fwd", "bwd"]
    tmp["fwd"] = pd.to_numeric(tmp["fwd"], errors="coerce").fillna(0)
    tmp["bwd"] = pd.to_numeric(tmp["bwd"], errors="coerce").fillna(0)
    tmp["total"] = tmp["fwd"] + tmp["bwd"]
    top_pairs = tmp.sort_values("total", ascending=False).head(MAX_BARS)

    fig = px.density_heatmap(top_pairs, x="package1", y="package2", z="total",
                              title="Circular dependencies heatmap (top pairs)")
    fig.update_layout(width=900, height=700, xaxis_title="package1", yaxis_title="package2")
    return fig


# ============================================================================
# SECTION 2: EXTERNAL DEPENDENCIES
# ============================================================================

def create_external_treemap(df: pd.DataFrame, c_group: str, c_name: str):
    """Create treemap for external dependencies (group → artifact)."""
    df_work = df.copy()
    df_work["group"] = labelize_na(df_work[c_group])
    df_work["name"] = labelize_na(df_work[c_name])
    treemap = (df_work.groupby(["group", "name"]).size()
                      .reset_index(name="count"))

    fig = px.treemap(treemap, path=["group", "name"], values="count",
                     title="External dependencies (group → artifact)")
    fig.update_layout(width=1000, height=650)
    return fig


def create_top_groups_bar(df: pd.DataFrame, c_group: str, c_name: str):
    """Create bar chart for top groups by number of artifacts used."""
    df_work = df.copy()
    df_work["group"] = labelize_na(df_work[c_group])
    df_work["name"] = labelize_na(df_work[c_name])
    treemap = (df_work.groupby(["group", "name"]).size()
                      .reset_index(name="count"))

    by_group = treemap.groupby("group")["count"].sum().reset_index(name="artifacts")
    top_groups = by_group.sort_values("artifacts", ascending=False).head(MAX_BARS)

    fig = px.bar(top_groups, x="group", y="artifacts", text="artifacts",
                 title="Top groups by number of artifacts used",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-30, width=1100, height=550,
                      xaxis_title="group", yaxis_title="artifacts used")
    return fig


# ============================================================================
# SECTION 3: LINES OF CODE
# ============================================================================

def create_top_loc_bar(df: pd.DataFrame, c_cls: str, c_loc: str):
    """Create bar chart for top classes by lines of code."""
    df_work = df.copy()
    df_work["LoC"] = pd.to_numeric(df_work[c_loc], errors="coerce").fillna(0).astype(int)
    top_loc = df_work.sort_values("LoC", ascending=False).head(MAX_BARS)

    fig = px.bar(top_loc, x=c_cls, y="LoC", text="LoC",
                 title="Top classes by lines of code",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-40, width=1200, height=550,
                      xaxis_title="class", yaxis_title="LoC")
    return fig


def create_loc_share_donut(df: pd.DataFrame, c_cls: str, c_loc: str):
    """Create donut chart for LoC share (Top classes)."""
    df_work = df.copy()
    df_work["LoC"] = pd.to_numeric(df_work[c_loc], errors="coerce").fillna(0).astype(int)
    top_loc = df_work.sort_values("LoC", ascending=False).head(MAX_BARS)

    fig = px.pie(top_loc, names=c_cls, values="LoC", hole=0.35,
                 title=f"LoC share — Top {len(top_loc)} classes")
    fig.update_traces(textposition="inside")
    fig.update_layout(width=850, height=650)
    return fig


# ============================================================================
# SECTION 4: MODULES & ARTIFACTS
# ============================================================================

def create_artifact_degree_scatter(df: pd.DataFrame, c_a1: str, c_a2: str):
    """Create scatter plot for artifact degree: outgoing vs incoming."""
    a1 = df[c_a1].astype(str)
    a2 = df[c_a2].astype(str)
    out_deg = a1.value_counts().rename("outgoing").to_frame()
    in_deg = a2.value_counts().rename("incoming").to_frame()
    deg = out_deg.join(in_deg, how="outer").fillna(0).astype(int).reset_index().rename(columns={"index": "artifact"})
    deg["total"] = deg["outgoing"] + deg["incoming"]

    fig = px.scatter(deg, x="outgoing", y="incoming", size="total", hover_name="artifact",
                     title="Artifact degree: outgoing vs incoming (size = total)")
    fig.update_layout(width=900, height=650, xaxis_title="outgoing", yaxis_title="incoming")
    return fig


def create_top_outgoing_bar(df: pd.DataFrame, c_a1: str, c_a2: str):
    """Create bar chart for top artifacts by number of outgoing dependencies."""
    a1 = df[c_a1].astype(str)
    a2 = df[c_a2].astype(str)
    out_deg = a1.value_counts().rename("outgoing").to_frame()
    in_deg = a2.value_counts().rename("incoming").to_frame()
    deg = out_deg.join(in_deg, how="outer").fillna(0).astype(int).reset_index().rename(columns={"index": "artifact"})

    top_out = deg.sort_values("outgoing", ascending=False).head(MAX_BARS)

    fig = px.bar(top_out, x="artifact", y="outgoing", text="outgoing",
                 title="Top artifacts by number of outgoing dependencies",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, width=1100, height=550,
                      xaxis_title="artifact", yaxis_title="outgoing dependencies")
    return fig


# ============================================================================
# SECTION 5: PACKAGE DEPENDENCIES
# ============================================================================

def create_package_deps_grouped_bar(df: pd.DataFrame, c_org: str, c_dst: str, c_types: str, c_total: str):
    """Create grouped bar chart for top origin packages: total deps vs distinct dependent types."""
    tmp = df[[c_org, c_dst, c_types, c_total]].copy()
    tmp.columns = ["origin", "destination", "types", "total"]
    tmp["types"] = pd.to_numeric(tmp["types"], errors="coerce").fillna(0).astype(int)
    tmp["total"] = pd.to_numeric(tmp["total"], errors="coerce").fillna(0).astype(int)

    agg = tmp.groupby("origin").agg(
        totalDeps=("total", "sum"),
        distinctTypes=("types", "sum")
    ).reset_index()

    top_origins = agg.sort_values("totalDeps", ascending=False).head(MAX_BARS)

    fig = px.bar(top_origins, x="origin", y=["totalDeps", "distinctTypes"],
                 barmode="group",
                 title="Top origin packages: total deps vs distinct dependent types",
                 color_discrete_sequence=["#1f77b4", "#ff7f0e"])
    fig.update_layout(xaxis_tickangle=-35, width=1200, height=600,
                      xaxis_title="origin package", yaxis_title="count")
    return fig


def create_package_pairs_heatmap(df: pd.DataFrame, c_org: str, c_dst: str, c_total: str):
    """Create heatmap for top origin → destination package pairs by total dependencies."""
    tmp = df[[c_org, c_dst, c_total]].copy()
    tmp.columns = ["origin", "destination", "total"]
    tmp["total"] = pd.to_numeric(tmp["total"], errors="coerce").fillna(0).astype(int)

    pairs = tmp.sort_values("total", ascending=False).head(30)

    fig = px.density_heatmap(pairs, x="origin", y="destination", z="total",
                              title="Top origin → destination package pairs by total dependencies")
    fig.update_layout(width=1000, height=700, xaxis_title="origin", yaxis_title="destination")
    return fig


# ============================================================================
# SECTION 6: PACKAGE DEPENDENCIES CLASSES
# ============================================================================

def create_class_pairs_bar(df: pd.DataFrame, c_c1: str, c_w: str, c_c2: str):
    """Create bar chart for top class-to-class dependencies by weight."""
    tmp = df[[c_c1, c_w, c_c2]].copy()
    tmp.columns = ["class1", "weight", "class2"]
    tmp["weight"] = pd.to_numeric(tmp["weight"], errors="coerce").fillna(0)

    top_pairs = tmp.sort_values("weight", ascending=False).head(MAX_BARS)

    fig = px.bar(top_pairs,
                 x=top_pairs["class1"] + " → " + top_pairs["class2"],
                 y="weight", text="weight",
                 title="Top class-to-class dependencies by weight",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-40, width=1200, height=600,
                      xaxis_title="class pair", yaxis_title="weight")
    return fig


# ============================================================================
# STREAMLIT RENDER FUNCTIONS
# ============================================================================

def render_circular_dependencies(df: pd.DataFrame):
    """Render circular dependencies charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Circular Dependencies analysis. The CSV file may be missing or empty.")
        return

    c_p1 = find_col(df, "package1", contains="package1", default=None)
    c_p2 = find_col(df, "package2", contains="package2", default=None)
    c_fwd = find_col(df, "totalDepsP1toP2", contains="p1top2", default=None)
    c_bwd = find_col(df, "totalDepsP2toP1", contains="p2top1", default=None)

    if not all([c_p1, c_p2, c_fwd, c_bwd]):
        st.warning("Missing required columns for Circular Dependencies analysis.")
        return

    st.subheader("1A) Top Circular Package Pairs by Total Dependencies")
    fig = create_circular_pairs_bar(df, c_p1, c_p2, c_fwd, c_bwd)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1B) Circular Dependencies Heatmap")
    fig = create_circular_heatmap(df, c_p1, c_p2, c_fwd, c_bwd)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_external_dependencies(df: pd.DataFrame):
    """Render external dependencies charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for External Dependencies analysis. The CSV file may be missing or empty.")
        return

    c_group = find_col(df, "group", "artifact.group", contains="group", default=None)
    c_name = find_col(df, "name", "artifact.name", contains="name", default=None)

    if not all([c_group, c_name]):
        st.warning("Missing required columns for External Dependencies analysis.")
        return

    st.subheader("2A) External Dependencies Treemap")
    fig = create_external_treemap(df, c_group, c_name)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("2B) Top Groups by Number of Artifacts Used")
    fig = create_top_groups_bar(df, c_group, c_name)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_lines_of_code(df: pd.DataFrame):
    """Render lines of code charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Lines of Code analysis. The CSV file may be missing or empty.")
        return

    c_cls = find_col(df, "CompleteClassPath", contains="class", default=None)
    c_loc = find_col(df, "LoC", contains="loc", default=None)

    if not all([c_cls, c_loc]):
        st.warning("Missing required columns for Lines of Code analysis.")
        return

    st.subheader("3A) Top Classes by Lines of Code")
    fig = create_top_loc_bar(df, c_cls, c_loc)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("3B) LoC Share (Top Classes)")
    fig = create_loc_share_donut(df, c_cls, c_loc)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_modules_and_artifacts(df: pd.DataFrame):
    """Render modules and artifacts charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Modules & Artifacts analysis. The CSV file may be missing or empty.")
        return

    c_a1 = find_col(df, "Artifact_1_Name", contains="_1_name", default=None)
    c_a2 = find_col(df, "Artifact_2_Name", contains="_2_name", default=None)

    if not all([c_a1, c_a2]):
        st.warning("Missing required columns for Modules & Artifacts analysis.")
        return

    st.subheader("4A) Artifact Degree: Outgoing vs Incoming")
    fig = create_artifact_degree_scatter(df, c_a1, c_a2)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("4B) Top Artifacts by Outgoing Dependencies")
    fig = create_top_outgoing_bar(df, c_a1, c_a2)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_package_dependencies(df: pd.DataFrame):
    """Render package dependencies charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Package Dependencies analysis. The CSV file may be missing or empty.")
        return

    c_org = find_col(df, "originPackage", contains="origin", default=None)
    c_dst = find_col(df, "destinationPackage", contains="destination", default=None)
    c_types = find_col(df, "typesThatDepend", contains="types", default=None)
    c_total = find_col(df, "totalDependencies", contains="total", default=None)

    if not all([c_org, c_dst, c_types, c_total]):
        st.warning("Missing required columns for Package Dependencies analysis.")
        return

    st.subheader("5A) Top Origin Packages: Total Deps vs Distinct Dependent Types")
    fig = create_package_deps_grouped_bar(df, c_org, c_dst, c_types, c_total)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("5B) Top Origin → Destination Package Pairs")
    fig = create_package_pairs_heatmap(df, c_org, c_dst, c_total)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_package_dependencies_classes(df: pd.DataFrame):
    """Render package dependencies classes chart in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Package Dependencies Classes analysis. The CSV file may be missing or empty.")
        return

    c_c1 = find_col(df, "Class_1_fqn", contains="_1_fqn", default=None)
    c_w = find_col(df, "dependencyWeight", contains="weight", default=None)
    c_c2 = find_col(df, "Class_2_fqn", contains="_2_fqn", default=None)

    if not all([c_c1, c_w, c_c2]):
        st.warning("Missing required columns for Package Dependencies Classes analysis.")
        return

    st.subheader("6A) Top Class-to-Class Dependencies by Weight")
    fig = create_class_pairs_bar(df, c_c1, c_w, c_c2)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

import pandas as pd
import plotly.express as px
import numpy as np
from pathlib import Path
import sys

# Add parent directory to path to import helpers
sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import fillna_safe, shorten_label


def create_visibility_chart(df: pd.DataFrame, c_vis: str):
    """Create visibility distribution chart.

    Returns: plotly figure or None if column not found
    """
    if not c_vis:
        return None

    vis_counts = fillna_safe(df[c_vis], "unknown").astype(str).value_counts().reset_index()
    vis_counts.columns = ["visibility", "count"]
    fig = px.bar(vis_counts, x="visibility", y="count",
                 title="main(String[]) visibility distribution", text_auto=True)
    fig.update_layout(width=900, height=420, xaxis_title="visibility", yaxis_title="count")
    return fig

def create_static_chart(df: pd.DataFrame, c_static: str):
    """Create static vs non-static pie chart.

    Returns: plotly figure or None if column not found
    """
    if not c_static:
        return None

    stat = fillna_safe(df[c_static], False).map(lambda x: "static" if bool(x) else "non-static")
    stat_counts = stat.value_counts().reset_index()
    stat_counts.columns = ["kind", "count"]
    fig = px.pie(stat_counts, names="kind", values="count",
                 title="static vs non-static main methods", hole=0.35)
    fig.update_layout(width=700, height=450)
    fig.update_traces(textposition="outside")
    return fig

def create_top_classes_chart(df: pd.DataFrame, c_main: str):
    """Create top classes with main() chart.

    Returns: plotly figure or None if column not found
    """
    if not c_main:
        return None

    top_classes = df[c_main].astype(str).value_counts().reset_index()
    top_classes.columns = ["className", "count"]
    fig = px.bar(top_classes.head(30), x="className", y="count",
                 title="Classes with main() — Top 30", text_auto=True)
    fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                     xaxis_title="class", yaxis_title="count")
    return fig

def create_signature_chart(df: pd.DataFrame, c_sig: str):
    """Create method signature variants chart.

    Returns: plotly figure or None if column not found
    """
    if not c_sig:
        return None

    sig_counts = fillna_safe(df[c_sig], "unknown").astype(str).value_counts().reset_index()
    sig_counts.columns = ["signature", "count"]
    fig = px.bar(sig_counts.head(20), x="signature", y="count",
                 title="Main method signature variants (Top 20)", text_auto=True)
    fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                     xaxis_title="signature", yaxis_title="count")
    return fig


def render_main_classes_charts(df: pd.DataFrame):
    """Render all charts for Main Classes analysis in Streamlit.

    Expected columns: mainClass, isStatic, visibility, signature
    """
    import streamlit as st

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
    st.subheader("1A) Visibility Distribution")
    fig = create_visibility_chart(df, c_vis)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'visibility' not found — skipping visibility chart.")

    # Chart 1B: Static vs non-static
    st.subheader("1B) Static vs Non-Static")
    fig = create_static_chart(df, c_static)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'isStatic' not found — skipping static/non-static chart.")

    # Chart 1C: Top classes exposing main()
    st.subheader("1C) Top Classes with main() Method")
    fig = create_top_classes_chart(df, c_main)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'mainClass' not found — skipping top classes chart.")

    # Chart 1D: Signature variants
    st.subheader("1D) Method Signature Variants")
    fig = create_signature_chart(df, c_sig)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'signature' not found — skipping signature chart.")


def create_controller_stereotypes_chart(df: pd.DataFrame, c_pkg: str):
    """Create controller stereotypes pie chart.

    Returns: plotly figure or None if column not found
    """
    if not c_pkg:
        return None

    simp = df[c_pkg].astype(str).map(lambda s: s.split(".")[-1] if "." in s else s)
    pkg_counts = simp.value_counts().reset_index()
    pkg_counts.columns = ["stereotype", "count"]
    fig = px.pie(pkg_counts, names="stereotype", values="count",
                 hole=0.35, title="Controller stereotypes")
    fig.update_layout(width=700, height=450)
    fig.update_traces(textposition="outside")
    return fig

def create_top_controllers_chart(df: pd.DataFrame, c_cls: str):
    """Create top controllers bar chart.

    Returns: plotly figure or None if column not found
    """
    if not c_cls:
        return None

    ctrl_counts = df[c_cls].astype(str).value_counts().reset_index()
    ctrl_counts.columns = ["controller", "count"]
    fig = px.bar(ctrl_counts.head(30), x="controller", y="count",
                 title="Controllers — Top 30", text_auto=True)
    fig.update_layout(width=1100, height=500, xaxis_tickangle=45,
                     xaxis_title="controller", yaxis_title="count")
    return fig


def render_spring_controllers_charts(df: pd.DataFrame):
    """Render all charts for Spring Controllers analysis in Streamlit.

    Expected columns: ControllerClassFqn, Package
    """
    import streamlit as st

    if df.empty:
        st.info("No data available for Spring Controllers analysis. The CSV file may be missing or empty.")
        return

    # Normalize column names to lowercase for easier access
    cols = {c.lower(): c for c in df.columns}
    c_cls = cols.get("controllerclassfqn") or cols.get("controller") or cols.get("classname")
    c_pkg = cols.get("package")

    # Chart 2A: Stereotype distribution
    st.subheader("2A) Controller Stereotypes")
    fig = create_controller_stereotypes_chart(df, c_pkg)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'Package' not found — skipping stereotype chart.")

    # Chart 2B: Top Controllers
    st.subheader("2B) Top Controllers")
    fig = create_top_controllers_chart(df, c_cls)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'ControllerClassFqn' not found — skipping top controllers chart.")


def create_endpoints_sunburst_chart(df: pd.DataFrame, c_ctrl: str, c_http: str, c_path: str):
    """Create endpoints sunburst chart (Controller → HTTP Method → Path).

    Returns: plotly figure or None if required columns not found
    """
    if not all([c_ctrl, c_http, c_path]):
        return None

    sub = df[[c_ctrl, c_http, c_path]].copy()
    fig = px.sunburst(sub, path=[c_ctrl, c_http, c_path],
                      maxdepth=3, title="Endpoints by Controller → HTTP Method → Path")
    fig.update_layout(width=1200, height=800,
                      margin=dict(l=40, r=40, t=80, b=40),
                      uniformtext_minsize=10, uniformtext_mode='hide')
    return fig

def create_http_method_distribution_chart(df: pd.DataFrame, c_http: str):
    """Create HTTP method distribution bar chart.

    Returns: plotly figure or None if column not found
    """
    if not c_http:
        return None

    method_counts = df[c_http].mask(df[c_http].isna(), "unknown").value_counts().reset_index()
    method_counts.columns = ["httpMethod", "count"]
    fig = px.bar(method_counts, x="httpMethod", y="count",
                 title="HTTP Method distribution", text_auto=True)
    fig.update_layout(width=900, height=420, xaxis_title="httpMethod", yaxis_title="count")
    return fig

def create_endpoints_per_controller_chart(df: pd.DataFrame, c_ctrl: str, c_path: str):
    """Create endpoints per controller horizontal bar chart.

    Returns: plotly figure or None if required columns not found
    """
    if not all([c_ctrl, c_path]):
        return None

    per_ctrl = (
        df.groupby(c_ctrl)[c_path]
            .nunique()
            .reset_index()
            .sort_values(c_path, ascending=False)
            .head(30)
    )
    per_ctrl.columns = ["controller", "uniqueEndpoints"]
    per_ctrl["controller_short"] = per_ctrl["controller"].map(lambda s: shorten_label(s, 50))
    h = max(600, 24 * len(per_ctrl))

    fig = px.bar(per_ctrl, x="uniqueEndpoints", y="controller_short",
                 orientation="h", title="Unique endpoints per controller (Top 30)",
                 text_auto=True, color_discrete_sequence=["#1f77b4"])
    fig.update_layout(height=h, width=1100, xaxis_title="unique endpoints",
                     yaxis_title="controller", yaxis=dict(autorange="reversed"),
                     margin=dict(l=10, r=10, t=80, b=10))
    fig.update_traces(hovertemplate="<b>%{customdata[0]}</b><br>unique endpoints: %{x}<extra></extra>",
                      customdata=np.stack([per_ctrl['controller']], axis=-1))
    return fig


def render_spring_endpoints_charts(df: pd.DataFrame):
    """Render all charts for Spring Endpoints analysis in Streamlit.

    Expected columns: controller, method, httpMethod, completeEndpoint
    """
    import streamlit as st

    if df.empty:
        st.info("No data available for Spring Endpoints analysis. The CSV file may be missing or empty.")
        return

    # Normalize column names to lowercase for easier access
    cols = {c.lower(): c for c in df.columns}
    c_ctrl = cols.get("controller")
    c_meth = cols.get("method")
    c_http = cols.get("httpmethod") or cols.get("httprequestmethod") or cols.get("methodtype")
    c_path = cols.get("completeendpoint") or cols.get("path") or cols.get("endpoint")

    # Ensure string types
    if c_ctrl: df[c_ctrl] = df[c_ctrl].astype(str)
    if c_meth: df[c_meth] = df[c_meth].astype(str)
    if c_http: df[c_http] = df[c_http].astype(str)
    if c_path: df[c_path] = df[c_path].astype(str)

    # Chart 3A: Sunburst
    st.subheader("3A) Endpoints Hierarchy (Controller → HTTP Method → Path)")
    fig = create_endpoints_sunburst_chart(df, c_ctrl, c_http, c_path)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Missing one of [controller, httpMethod, completeEndpoint] — skipping sunburst.")

    # Chart 3B: HTTP method distribution
    st.subheader("3B) HTTP Method Distribution")
    fig = create_http_method_distribution_chart(df, c_http)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Column 'httpMethod' not found — skipping HTTP method distribution.")

    # Chart 3C: Endpoints per controller
    st.subheader("3C) Endpoints Per Controller")
    fig = create_endpoints_per_controller_chart(df, c_ctrl, c_path)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Missing controller/path columns — skipping endpoints per controller chart.")

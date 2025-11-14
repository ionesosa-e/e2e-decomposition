import plotly.express as px
import pandas as pd
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import find_col

MAX_ROWS_PREVIEW = 5
MAX_BARS = 30



def create_deprecated_adapter_donut(df: pd.DataFrame, c_depr: str):
    """Create donut chart for deprecated adapter usage."""
    donut = df[c_depr].value_counts().rename_axis("usesDeprecatedAdapter").reset_index(name="count")
    donut["usesDeprecatedAdapter"] = donut["usesDeprecatedAdapter"].map({True: "Yes", False: "No"})

    fig = px.pie(donut, values="count", names="usesDeprecatedAdapter",
                 title="Uses deprecated adapter?", hole=0.5)
    fig.update_layout(height=480, width=640)
    return fig


def create_parent_class_sunburst(df: pd.DataFrame, c_ext: str, c_cls: str, c_cfgc: str):
    """Create sunburst for parent class → config class (size = config method count)."""
    sb = df.copy()
    sb[c_ext] = sb[c_ext].fillna("").replace({"": "(no parent)"})

    fig = px.sunburst(sb, path=[c_ext, c_cls], values=c_cfgc,
                      title="Security configs by parent class (size = config method count)")
    fig.update_layout(height=650, width=900)
    return fig


def create_annotation_density_treemap(df: pd.DataFrame, c_cls: str, c_annc: str):
    """Create treemap for annotation density per config class."""
    fig = px.treemap(df.sort_values(c_annc, ascending=False).head(60),
                     path=[c_cls], values=c_annc,
                     title="Security configurations — annotation density (treemap)")
    fig.update_layout(height=650, width=900)
    return fig


def create_config_methods_pie(df: pd.DataFrame, c_cls: str, c_cfgs: str):
    """Create optional pie chart for configuration methods used."""
    if c_cfgs not in df.columns:
        return None

    exploded = (df[[c_cls, c_cfgs]]
                .assign(methods=df[c_cfgs].fillna("").astype(str).str.split(";")))
    exploded = exploded.explode("methods")
    exploded["methods"] = exploded["methods"].str.strip()
    exploded = exploded[exploded["methods"] != ""]

    if exploded.empty:
        return None

    agg = exploded["methods"].value_counts().rename_axis("method").reset_index(name="count")

    fig = px.pie(agg, values="count", names="method",
                 title="Configuration methods used (across all config classes)", hole=0.45)
    fig.update_layout(height=520, width=720)
    return fig



def create_annotations_popularity_donut(df: pd.DataFrame, c_ann: str):
    """Create donut chart for security annotations popularity."""
    by_ann = df[c_ann].value_counts().rename_axis("annotation").reset_index(name="count")

    fig = px.pie(by_ann, values="count", names="annotation",
                 title="Security annotations used (global)", hole=0.45)
    fig.update_layout(height=480, width=640)
    return fig


def create_class_annotation_sunburst(df: pd.DataFrame, c_decl: str, c_ann: str):
    """Create sunburst for class → annotation breakdown."""
    sb = df.groupby([c_decl, c_ann]).size().reset_index(name="count")

    fig = px.sunburst(sb, path=[c_decl, c_ann], values="count",
                      title="Annotated methods by class and annotation")
    fig.update_layout(height=650, width=900)
    return fig


def create_top_classes_treemap(df: pd.DataFrame, c_decl: str):
    """Create treemap for top classes by number of security-annotated methods."""
    by_class = df[c_decl].value_counts().rename_axis("class").reset_index(name="count")

    fig = px.treemap(by_class.head(60), path=["class"], values="count",
                     title="Top classes by number of security-annotated methods (treemap)")
    fig.update_layout(height=650, width=900)
    return fig



def create_http_method_donut(df: pd.DataFrame, c_http: str):
    """Create donut chart for potentially unsecured endpoints by HTTP method."""
    by_http = df[c_http].value_counts().rename_axis("httpMethod").reset_index(name="count")

    fig = px.pie(by_http, values="count", names="httpMethod",
                 title="Potentially unsecured endpoints by HTTP method", hole=0.45)
    fig.update_layout(height=480, width=640)
    return fig


def create_controller_method_sunburst(df: pd.DataFrame, c_ctrl: str, c_http: str):
    """Create sunburst for controller → HTTP method."""
    sun = df.groupby([c_ctrl, c_http]).size().reset_index(name="count")

    fig = px.sunburst(sun, path=[c_ctrl, c_http], values="count",
                      title="Potentially unsecured endpoints by controller and method")
    fig.update_layout(height=650, width=900)
    return fig


def create_controllers_treemap(df: pd.DataFrame, c_ctrl: str):
    """Create treemap for controllers with most potentially unsecured endpoints."""
    by_ctrl = df[c_ctrl].value_counts().rename_axis("controller").reset_index(name="count")

    fig = px.treemap(by_ctrl.head(60), path=["controller"], values="count",
                     title="Controllers with most potentially unsecured endpoints (treemap)")
    fig.update_layout(height=650, width=900)
    return fig




def render_security_configurations(df: pd.DataFrame):
    """Render Security Configurations charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Security Configurations analysis. The CSV file may be missing or empty.")
        return

    c_cls = find_col(df, "securityConfigClass", contains="config")
    c_ext = find_col(df, "extendsClass", contains="extend", default="extendsClass")
    c_annc = find_col(df, "annotationsCount", contains="annot", default="annotationsCount")
    c_cfgc = find_col(df, "configMethodsCount", contains="config", default="configMethodsCount")
    c_cfgs = find_col(df, "configMethods", contains="config", default="configMethods")
    c_depr = find_col(df, "usesDeprecatedAdapter", contains="deprecated", default="usesDeprecatedAdapter")

    required = [c_cls, c_ext, c_annc, c_cfgc, c_depr]
    if any(col is None for col in required):
        st.warning("Missing required columns for Security Configurations analysis.")
        return

    # Ensure numeric/bool types
    df[c_annc] = pd.to_numeric(df[c_annc], errors="coerce").fillna(0)
    df[c_cfgc] = pd.to_numeric(df[c_cfgc], errors="coerce").fillna(0)
    if df[c_depr].dtype != bool:
        df[c_depr] = df[c_depr].astype(str).str.lower().isin(["true", "1", "yes", "y"])

    st.subheader("1A) Uses Deprecated Adapter?")
    fig = create_deprecated_adapter_donut(df, c_depr)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1B) Security Configs by Parent Class")
    fig = create_parent_class_sunburst(df, c_ext, c_cls, c_cfgc)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1C) Annotation Density per Config Class")
    fig = create_annotation_density_treemap(df, c_cls, c_annc)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    # Optional: Config methods pie
    if c_cfgs:
        st.subheader("1D) Configuration Methods Used (Optional)")
        fig = create_config_methods_pie(df, c_cls, c_cfgs)
        if fig:
            st.plotly_chart(fig, use_container_width=True)


def render_spring_security(df: pd.DataFrame):
    """Render Spring Security (annotated methods) charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Spring Security analysis. The CSV file may be missing or empty.")
        return

    c_decl = find_col(df, "declaringClass", contains="declaring")
    c_meth = find_col(df, "methodName", contains="method")
    c_ann = find_col(df, "annotationName", contains="annot")

    required = [c_decl, c_meth, c_ann]
    if any(col is None for col in required):
        st.warning("Missing required columns for Spring Security analysis.")
        return

    st.subheader("2A) Security Annotations Used (Global)")
    fig = create_annotations_popularity_donut(df, c_ann)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("2B) Annotated Methods by Class and Annotation")
    fig = create_class_annotation_sunburst(df, c_decl, c_ann)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("2C) Top Classes by Number of Security-Annotated Methods")
    fig = create_top_classes_treemap(df, c_decl)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_unsecured_endpoints(df: pd.DataFrame):
    """Render Potentially Unsecured Endpoints charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Unsecured Endpoints analysis. The CSV file may be missing or empty.")
        return

    c_ctrl = find_col(df, "Controller", contains="controller")
    c_meth = find_col(df, "Method", contains="method")
    c_http = find_col(df, "HttpMethod", contains="http")
    c_ep = find_col(df, "CompleteEndpoint", contains="endpoint")
    c_stat = find_col(df, "SecurityStatus", contains="security", default="SecurityStatus")

    required = [c_ctrl, c_meth, c_http, c_ep, c_stat]
    if any(col is None for col in required):
        st.warning("Missing required columns for Unsecured Endpoints analysis.")
        return

    st.subheader("3A) Potentially Unsecured Endpoints by HTTP Method")
    fig = create_http_method_donut(df, c_http)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("3B) Potentially Unsecured Endpoints by Controller and Method")
    fig = create_controller_method_sunburst(df, c_ctrl, c_http)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("3C) Controllers with Most Potentially Unsecured Endpoints")
    fig = create_controllers_treemap(df, c_ctrl)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.divider()

    st.subheader("3D) Complete List of Potentially Unsecured Endpoints")
    st.markdown("**⚠️ These endpoints may lack proper security annotations and could be vulnerable.**")

    detailed_endpoints = df[[c_ep, c_http, c_ctrl, c_meth, c_stat]].copy()
    detailed_endpoints.columns = ['Endpoint Path', 'HTTP Method', 'Controller', 'Method Name', 'Security Status']

    detailed_endpoints = detailed_endpoints.sort_values(['HTTP Method', 'Endpoint Path'])

    def highlight_insecure(row):
        if 'unsecured' in str(row['Security Status']).lower() or 'potentially' in str(row['Security Status']).lower():
            return ['background-color: #ffcccc'] * len(row)
        return [''] * len(row)

    st.markdown(f"**Total potentially unsecured endpoints found:** {len(detailed_endpoints)}")

    styled_df = detailed_endpoints.style.apply(highlight_insecure, axis=1)
    st.dataframe(
        styled_df,
        use_container_width=True,
        height=600,
        hide_index=True
    )

    st.divider()

    st.subheader("3E) Unsecured Endpoints Breakdown by HTTP Method")

    method_breakdown = detailed_endpoints.groupby('HTTP Method').size().reset_index(name='Count')
    method_breakdown = method_breakdown.sort_values('Count', ascending=False)
    st.dataframe(
        method_breakdown,
        use_container_width=True,
        hide_index=True
    )
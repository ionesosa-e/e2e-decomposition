import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))

DEFAULT_BAR_COLOR = ["#1f77b4"]

def build_hierarchy_from_fqns(fqns):
    """Build labels, parents, values for go.Treemap / go.Icicle from a list of fqns.

    Improved version that ensures all nodes have proper values.
    """
    def prefixes(fqn):
        parts = [p for p in str(fqn).split('.') if p]
        acc = []
        for p in parts:
            acc.append(p if not acc else acc[-1] + '.' + p)
        return acc

    nodes = set()
    for f in fqns:
        s = str(f).strip()
        if not s or s == 'nan':
            continue
        for pref in prefixes(s):
            nodes.add(pref)

    if not nodes:
        return [], [], []

    leaf_counter = {}
    for f in fqns:
        s = str(f).strip()
        if not s or s == 'nan':
            continue
        leaf_counter[s] = leaf_counter.get(s, 0) + 1

    labels, parents, values = [], [], []
    for node in sorted(nodes, key=lambda s: (s.count('.'), s)):
        label = node.split('.')[-1]

        if '.' in node:
            parent_fqn = node.rsplit('.', 1)[0]
            parent_label = parent_fqn.split('.')[-1]
        else:
            parent_label = ""

        value = leaf_counter.get(node, 0)

        if value == 0:
            for leaf_fqn, count in leaf_counter.items():
                if leaf_fqn.startswith(node + '.'):
                    value += count

        labels.append(label)
        parents.append(parent_label)
        values.append(value if value > 0 else 1)  # Ensure at least value of 1

    return labels, parents, values



def create_controllers_violations_chart(df, c_controller):
    """Create donut chart for controllers with most layer violations (Top 15)."""
    if not c_controller:
        return None
    cnt_ctrl = df[c_controller].value_counts().rename_axis("controller").reset_index(name="violations")
    if cnt_ctrl.empty:
        return None
    top_c = cnt_ctrl.head(15)
    fig = px.pie(top_c, values="violations", names="controller",
                 title="Controllers with most layer violations (Top 15)", hole=0.45)
    fig.update_layout(height=620, width=950)
    return fig

def create_repositories_bypassed_chart(df, c_repository):
    """Create treemap for repositories most frequently bypassed (Top 25)."""
    if not c_repository:
        return None
    cnt_repo = df[c_repository].value_counts().rename_axis("repository").reset_index(name="violations")
    if cnt_repo.empty:
        return None
    top_r = cnt_repo.head(25)
    fig = px.treemap(top_r, path=["repository"], values="violations",
                     title="Repositories most frequently bypassed")
    fig.update_layout(height=650, width=900)
    return fig

def create_layer_violation_sankey(df, c_controller, c_repository, sample_size=180):
    """Create Sankey diagram for Controller → Repository relationships (sampled)."""
    if not c_controller or not c_repository:
        return None
    sample = df[[c_controller, c_repository]].dropna().head(sample_size)
    if sample.empty:
        return None
    labels = pd.Index(sorted(set(sample[c_controller]) | set(sample[c_repository]))).tolist()
    idx = {name: i for i, name in enumerate(labels)}
    sources = sample[c_controller].map(idx).tolist()
    targets = sample[c_repository].map(idx).tolist()
    values = [1] * len(sample)
    fig = go.Figure(data=[go.Sankey(
        node=dict(label=labels, pad=10, thickness=12),
        link=dict(source=sources, target=targets, value=values)
    )])
    fig.update_layout(title_text="Controller → Repository (sampled)", height=600, width=1100)
    return fig



def create_complexity_violin_chart(df, c_cc):
    """Create violin chart for cyclomatic complexity distribution."""
    if not c_cc:
        return None
    df = df.copy()
    df[c_cc] = pd.to_numeric(df[c_cc], errors="coerce")
    df = df.dropna(subset=[c_cc])
    if df.empty:
        return None
    fig = px.violin(df, y=c_cc, box=True, points="outliers",
                    title="Cyclomatic complexity — violin")
    fig.update_layout(height=450, width=600)
    return fig

def create_complexity_scatter_chart(df, c_class, c_method, c_cc, top_n=120):
    """Create scatter plot for top methods by cyclomatic complexity."""
    if not all([c_class, c_method, c_cc]):
        return None
    df = df.copy()
    df[c_cc] = pd.to_numeric(df[c_cc], errors="coerce")
    df = df.dropna(subset=[c_cc])
    if df.empty:
        return None
    top = df.sort_values(c_cc, ascending=False).head(top_n)
    fig = px.scatter(top, x=c_method, y=c_cc, hover_data=[c_class],
                     title="Top methods by cyclomatic complexity (scatter)")
    fig.update_layout(xaxis_tickangle=-35, height=550, width=1100)
    return fig



def create_deepest_inheritance_bar(df, c_class, c_depth, top_n=25):
    """Create bar chart for classes with deepest inheritance."""
    if not c_class or not c_depth:
        return None
    df = df.copy()
    df[c_depth] = pd.to_numeric(df[c_depth], errors="coerce").fillna(0)
    if df.empty:
        return None
    top = df.sort_values(c_depth, ascending=False).head(top_n)
    fig = px.bar(top, x=c_class, y=c_depth, text=c_depth,
                 title=f"Deepest inheritance — top {top_n} classes",
                 color_discrete_sequence=DEFAULT_BAR_COLOR)
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-35, height=520, width=1100,
                      xaxis_title="class", yaxis_title="depth")
    return fig

def create_inheritance_distribution_histogram(df, c_depth):
    """Create improved histogram for inheritance depth distribution with statistics."""
    if not c_depth:
        return None
    df = df.copy()
    df[c_depth] = pd.to_numeric(df[c_depth], errors="coerce").fillna(0)
    if df.empty:
        return None

    mean_val = float(df[c_depth].mean())
    median_val = float(df[c_depth].median())
    p75_val = float(df[c_depth].quantile(0.75))
    p90_val = float(df[c_depth].quantile(0.90))

    fig = px.histogram(df, x=c_depth, nbins=30,
                       title="Inheritance depth — distribution with statistics",
                       color_discrete_sequence=["#636EFA"])

    fig.add_vline(x=mean_val, line_dash="dash", line_color="red", line_width=2,
                  annotation_text=f"Mean: {mean_val:.1f}",
                  annotation_position="top left",
                  annotation_font_color="red")
    fig.add_vline(x=median_val, line_dash="dot", line_color="green", line_width=2,
                  annotation_text=f"Median: {median_val:.1f}",
                  annotation_position="top",
                  annotation_font_color="green")
    fig.add_vline(x=p75_val, line_dash="dashdot", line_color="orange", line_width=2,
                  annotation_text=f"P75: {p75_val:.1f}",
                  annotation_position="top right",
                  annotation_font_color="orange")

    fig.update_layout(
        height=500,
        width=1000,
        xaxis_title="Inheritance Depth",
        yaxis_title="Number of Classes",
        showlegend=False,
        bargap=0.1
    )
    fig.update_traces(marker_line_width=0.5, marker_line_color="white")
    return fig



def create_excessive_dependencies_treemap(df, c_fqn, c_dep, top_n=50):
    """Create treemap for classes with excessive dependencies."""
    if not c_fqn or not c_dep:
        return None
    df = df.copy()
    df[c_dep] = pd.to_numeric(df[c_dep], errors="coerce").fillna(0)
    if df.empty:
        return None
    top = df.sort_values(c_dep, ascending=False).head(top_n)
    fig = px.treemap(top, path=[c_fqn], values=c_dep,
                     title="Classes with excessive dependencies (treemap)")
    fig.update_layout(height=650, width=900)
    return fig



def create_general_count_donut(df, c_info, c_count):
    """Create donut chart for general counts proportions."""
    if not c_info or not c_count:
        return None
    df = df.copy()
    df[c_count] = pd.to_numeric(df[c_count], errors="coerce").fillna(0)
    if df.empty:
        return None
    fig = px.pie(df, values=c_count, names=c_info,
                 title="General counts — proportions", hole=0.45)
    fig.update_layout(height=520, width=720)
    return fig



def create_god_classes_treemap(df, c_fqn, c_cnt, top_n=50):
    """Create treemap for God classes by method count."""
    if not c_fqn or not c_cnt:
        return None
    df = df.copy()
    df[c_cnt] = pd.to_numeric(df[c_cnt], errors="coerce").fillna(0)
    if df.empty:
        return None
    top = df.sort_values(c_cnt, ascending=False).head(top_n)
    fig = px.treemap(top, path=[c_fqn], values=c_cnt,
                     title="God classes — treemap by method count")
    fig.update_layout(height=650, width=900)
    return fig

def create_god_classes_histogram(df, c_cnt):
    """Create improved histogram for methods per class distribution (God classes)."""
    if not c_cnt:
        return None
    df = df.copy()
    df[c_cnt] = pd.to_numeric(df[c_cnt], errors="coerce").fillna(0)
    if df.empty:
        return None

    mean_val = float(df[c_cnt].mean())
    median_val = float(df[c_cnt].median())
    p75_val = float(df[c_cnt].quantile(0.75))
    p90_val = float(df[c_cnt].quantile(0.90))

    fig = px.histogram(df, x=c_cnt, nbins=40,
                       title="Methods per class — distribution (God classes)",
                       color_discrete_sequence=["#EF553B"])

    fig.add_vline(x=mean_val, line_dash="dash", line_color="blue", line_width=2,
                  annotation_text=f"Mean: {mean_val:.1f}",
                  annotation_position="top left",
                  annotation_font_color="blue")
    fig.add_vline(x=median_val, line_dash="dot", line_color="green", line_width=2,
                  annotation_text=f"Median: {median_val:.1f}",
                  annotation_position="top",
                  annotation_font_color="green")
    fig.add_vline(x=p90_val, line_dash="dashdot", line_color="red", line_width=2,
                  annotation_text=f"P90: {p90_val:.1f}",
                  annotation_position="top right",
                  annotation_font_color="red")

    fig.update_layout(
        height=500,
        width=1000,
        xaxis_title="Number of Methods",
        yaxis_title="Number of Classes",
        showlegend=False,
        bargap=0.1
    )
    fig.update_traces(marker_line_width=0.5, marker_line_color="white")
    return fig



def create_methods_polar_chart(df, c_class, c_cnt, top_n=25):
    """Create polar bar chart for top classes by number of methods."""
    if not c_class or not c_cnt:
        return None
    df = df.copy()
    df[c_cnt] = pd.to_numeric(df[c_cnt], errors="coerce").fillna(0)
    if df.empty:
        return None
    top = df.sort_values(c_cnt, ascending=False).head(top_n)
    fig = px.bar_polar(top, r=c_cnt, theta=c_class,
                       title="Top classes by number of methods (polar)")
    fig.update_layout(height=750, width=900)
    return fig

def create_methods_violin_chart(df, c_cnt):
    """Create violin chart for methods per class distribution."""
    if not c_cnt:
        return None
    df = df.copy()
    df[c_cnt] = pd.to_numeric(df[c_cnt], errors="coerce").fillna(0)
    if df.empty:
        return None
    fig = px.violin(df, y=c_cnt, box=True, points=False,
                    title="Methods per class — violin")
    fig.update_layout(height=450, width=600)
    return fig



def create_inheritance_sankey(df, c_c1, c_c2, sample_size=120):
    """Create improved Sankey diagram for inheritance graph (sampled with better styling)."""
    if not c_c1 or not c_c2:
        return None
    sample = df[[c_c1, c_c2]].dropna().head(sample_size)
    if sample.empty:
        return None

    all_classes = set(sample[c_c1]) | set(sample[c_c2])
    labels_full = sorted(all_classes)
    labels_short = [label.split('.')[-1] if '.' in label else label for label in labels_full]
    idx = {name: i for i, name in enumerate(labels_full)}

    sources = sample[c_c1].map(idx).tolist()
    targets = sample[c_c2].map(idx).tolist()
    values = [1] * len(sample)

    num_nodes = len(labels_short)
    node_colors = [f"rgba({100 + (i * 155 // num_nodes)}, {150}, {200 - (i * 100 // num_nodes)}, 0.8)"
                   for i in range(num_nodes)]

    fig = go.Figure(data=[go.Sankey(
        node=dict(
            label=labels_short,
            pad=15,
            thickness=20,
            line=dict(color="white", width=0.5),
            color=node_colors
        ),
        link=dict(
            source=sources,
            target=targets,
            value=values,
            color="rgba(0, 0, 0, 0.2)"
        )
    )])

    fig.update_layout(
        title_text=f"Inheritance graph — Top {sample_size} relationships",
        height=700,
        width=1200,
        font=dict(size=10)
    )
    return fig



def create_package_treemap(fqns):
    """Create improved treemap for package structure."""
    if not fqns or len(fqns) == 0:
        return None

    labels, parents, values = build_hierarchy_from_fqns(fqns)

    if not labels or len(labels) == 0:
        return None

    filtered_data = [(l, p, v) for l, p, v in zip(labels, parents, values) if v > 0 or p == ""]
    if not filtered_data:
        return None

    labels, parents, values = zip(*filtered_data)

    fig = go.Figure(go.Treemap(
        labels=list(labels),
        parents=list(parents),
        values=list(values),
        branchvalues="total",
        textposition="middle center",
        marker=dict(
            colorscale='Blues',
            cmid=sum(values) / len(values) if values else 0
        ),
        hovertemplate='<b>%{label}</b><br>Count: %{value}<br>%{percentParent}<extra></extra>'
    ))

    fig.update_layout(
        title="Package structure — hierarchical treemap",
        height=800,
        width=1000,
        margin=dict(t=50, l=25, r=25, b=25)
    )
    return fig

def create_package_icicle(fqns):
    """Create improved icicle chart for package structure."""
    if not fqns or len(fqns) == 0:
        return None

    labels, parents, values = build_hierarchy_from_fqns(fqns)

    if not labels or len(labels) == 0:
        return None

    filtered_data = [(l, p, v) for l, p, v in zip(labels, parents, values) if v > 0 or p == ""]
    if not filtered_data:
        return None

    labels, parents, values = zip(*filtered_data)

    fig = go.Figure(go.Icicle(
        labels=list(labels),
        parents=list(parents),
        values=list(values),
        branchvalues="total",
        tiling=dict(orientation='v'),
        marker=dict(
            colorscale='Viridis',
            line=dict(width=2, color='white')
        ),
        hovertemplate='<b>%{label}</b><br>Count: %{value}<br>%{percentParent}<extra></extra>'
    ))

    fig.update_layout(
        title="Package structure — icicle diagram",
        height=800,
        width=1000,
        margin=dict(t=50, l=25, r=25, b=25)
    )
    return fig



def find_col(df, *cands, default=None, contains=None):
    """Return a column name by exact candidates or substring (case-insensitive)."""
    if df is None or df.empty:
        return default
    low = {c.lower(): c for c in df.columns}
    for c in cands:
        if c and c.lower() in low:
            return low[c.lower()]
    if contains:
        for k, orig in low.items():
            if contains.lower() in k:
                return orig
    return default



def render_layer_violations(df: pd.DataFrame):
    """Render Architectural Layer Violations section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Architectural Layer Violations.")
        return

    c_controller = find_col(df, "Controller", contains="controller")
    c_repository = find_col(df, "Repository", contains="repositor")

    if not (c_controller and c_repository):
        st.warning("Required columns not found (Controller, Repository).")
        return

    st.subheader("1A) Controllers with Most Layer Violations")
    fig = create_controllers_violations_chart(df, c_controller)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1B) Repositories Most Frequently Bypassed")
    fig = create_repositories_bypassed_chart(df, c_repository)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1C) Controller → Repository Flow")
    fig = create_layer_violation_sankey(df, c_controller, c_repository)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_cyclomatic_complexity(df: pd.DataFrame):
    """Render Cyclomatic Complexity section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Cyclomatic Complexity.")
        return

    c_class = find_col(df, "Class", contains="class")
    c_method = find_col(df, "Method", contains="method")
    c_cc = find_col(df, "cyclomaticComplexity", contains="complex", default="cyclomaticComplexity")

    if not all([c_class, c_method, c_cc]):
        st.warning("Required columns not found.")
        return

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("2A) Complexity Distribution")
        fig = create_complexity_violin_chart(df, c_cc)
        if fig:
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("2B) Top Methods by Complexity")
        fig = create_complexity_scatter_chart(df, c_class, c_method, c_cc)
        if fig:
            st.plotly_chart(fig, use_container_width=True)

def render_deepest_inheritance(df: pd.DataFrame):
    """Render Deepest Inheritance section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Deepest Inheritance.")
        return

    c_class = find_col(df, "class.fqn", "Class", contains="class")
    c_depth = find_col(df, "Depth", contains="depth", default="Depth")

    if not (c_class and c_depth):
        st.warning("Required columns not found.")
        return

    st.subheader("3A) Classes with Deepest Inheritance")
    fig = create_deepest_inheritance_bar(df, c_class, c_depth)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("3B) Inheritance Depth Distribution")
    fig = create_inheritance_distribution_histogram(df, c_depth)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_excessive_dependencies(df: pd.DataFrame):
    """Render Excessive Dependencies section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Excessive Dependencies.")
        return

    c_fqn = find_col(df, "classFqn", contains="fqn", default="classFqn")
    c_dep = find_col(df, "dependencies", contains="depend", default="dependencies")

    if not (c_fqn and c_dep):
        st.warning("Required columns not found.")
        return

    st.subheader("4A) Classes with Excessive Dependencies")
    fig = create_excessive_dependencies_treemap(df, c_fqn, c_dep)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_general_count_overview(df: pd.DataFrame):
    """Render General Count Overview section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for General Count Overview.")
        return

    c_info = find_col(df, "Info", contains="info", default="Info")
    c_count = find_col(df, "Count", contains="count", default="Count")

    if not (c_info and c_count):
        st.warning("Required columns not found.")
        return

    st.subheader("5A) General Counts — Proportions")
    fig = create_general_count_donut(df, c_info, c_count)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_god_classes(df: pd.DataFrame):
    """Render God Classes section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for God Classes.")
        return

    c_fqn = find_col(df, "fqn_god_class", contains="fqn", default="fqn_god_class")
    c_cnt = find_col(df, "methodCount", contains="method", default="methodCount")

    if not (c_fqn and c_cnt):
        st.warning("Required columns not found.")
        return

    st.subheader("6A) God Classes by Method Count")
    fig = create_god_classes_treemap(df, c_fqn, c_cnt)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("6B) Methods per Class Distribution")
    fig = create_god_classes_histogram(df, c_cnt)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_highest_methods(df: pd.DataFrame):
    """Render Highest Number of Methods section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Highest Number of Methods.")
        return

    c_class = find_col(df, "class.fqn", "Class", contains="class")
    c_cnt = find_col(df, "methodCount", contains="method", default="methodCount")

    if not (c_class and c_cnt):
        st.warning("Required columns not found.")
        return

    st.subheader("7A) Top Classes by Number of Methods")
    fig = create_methods_polar_chart(df, c_class, c_cnt)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("7B) Methods per Class Distribution")
    fig = create_methods_violin_chart(df, c_cnt)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

def render_inheritance_between_classes(df: pd.DataFrame):
    """Render Inheritance Between Classes section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Inheritance Between Classes.")
        return

    c_c1 = find_col(df, "class_1_fqn", contains="class_1")
    c_c2 = find_col(df, "class_2_fqn", contains="class_2")

    if not (c_c1 and c_c2):
        st.warning("Required columns not found.")
        return

    st.subheader("8A) Inheritance Graph (Sampled)")
    fig = create_inheritance_sankey(df, c_c1, c_c2)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No inheritance relationships found in sample.")

def render_package_structure(df: pd.DataFrame):
    """Render Package Structure section for Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Package Structure.")
        return

    c_pkg = find_col(df, "packageFqn", contains="package", default=None)

    if not c_pkg:
        st.warning("Package column not found.")
        return

    fqns = df[c_pkg].dropna().astype(str).tolist()

    if not fqns:
        st.info("No package data found.")
        return

    st.subheader("9A) Package Structure — Treemap")
    fig = create_package_treemap(fqns)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("9B) Package Structure — Icicle")
    fig = create_package_icicle(fqns)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

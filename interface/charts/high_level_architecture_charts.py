import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))

DEFAULT_BAR_COLOR = ["#1f77b4"]

def build_hierarchy_from_fqns(fqns):
    """Build labels, parents, values, and text for go.Treemap / go.Icicle from a list of fqns.

    Returns (labels, parents, values, text) where:
    - labels: Full FQN paths for uniqueness (e.g., "com.encora.spark.model")
    - parents: Full FQN paths of parent nodes (e.g., "com.encora.spark")
    - values: Aggregated counts bottom-up
    - text: Short display names (e.g., "model")
    """
    def prefixes(fqn):
        """Generate all prefixes of an FQN."""
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
        return [], [], [], []

    leaf_counter = {}
    for f in fqns:
        s = str(f).strip()
        if not s or s == 'nan':
            continue
        leaf_counter[s] = leaf_counter.get(s, 0) + 1

    node_values = {}
    for node in sorted(nodes, key=lambda s: (-s.count('.'), s)):  # Process deepest first
        if node in leaf_counter:
            node_values[node] = leaf_counter[node]
        else:
            # Sum all direct children
            child_sum = 0
            for other_node in nodes:
                if other_node.startswith(node + '.') and other_node.count('.') == node.count('.') + 1:
                    child_sum += node_values.get(other_node, 0)
            node_values[node] = child_sum

    labels, parents, values, text = [], [], [], []
    for node in sorted(nodes, key=lambda s: (s.count('.'), s)):
        # Use full FQN as label for uniqueness
        label = node

        if '.' in node:
            parent_fqn = node.rsplit('.', 1)[0]
        else:
            parent_fqn = ""

        short_name = node.split('.')[-1]

        labels.append(label)
        parents.append(parent_fqn)
        values.append(node_values.get(node, 1))  # Ensure at least 1
        text.append(short_name)

    return labels, parents, values, text



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



def create_inheritance_sankey(df, c_c1, c_c2, sample_size=50):
    if not c_c1 or not c_c2:
        return None

    parent_counts = df[c_c2].value_counts().head(10)  # Top 10 parent classes
    top_parents = set(parent_counts.index)

    filtered = df[df[c_c2].isin(top_parents)][[c_c1, c_c2]].dropna().head(sample_size)

    if filtered.empty:
        return None

    all_classes = set(filtered[c_c1]) | set(filtered[c_c2])
    labels_full = sorted(all_classes)

    def get_display_label(fqn):
        parts = fqn.split('.')
        if len(parts) >= 2:
            return f"{parts[-2]}.{parts[-1]}"
        return parts[-1] if parts else fqn

    labels_display = [get_display_label(label) for label in labels_full]
    idx = {name: i for i, name in enumerate(labels_full)}

    sources = filtered[c_c1].map(idx).tolist()
    targets = filtered[c_c2].map(idx).tolist()
    values = [1] * len(filtered)

    num_nodes = len(labels_display)
    pad = max(10, min(20, 300 // num_nodes))  # Adjust padding based on density
    thickness = max(12, min(20, 400 // num_nodes))  # Adjust thickness based on density

    parent_set = set(filtered[c_c2])
    node_colors = []
    for label in labels_full:
        if label in parent_set:
            node_colors.append("rgba(65, 105, 225, 0.8)")  # Royal Blue for parents
        else:
            node_colors.append("rgba(60, 179, 113, 0.8)")  # Medium Sea Green for children

    fig = go.Figure(data=[go.Sankey(
        arrangement='snap',  # Better auto-layout
        node=dict(
            label=labels_display,
            pad=pad,
            thickness=thickness,
            line=dict(color="white", width=1),
            color=node_colors
        ),
        link=dict(
            source=sources,
            target=targets,
            value=values,
            color="rgba(0, 0, 0, 0.15)"
        )
    )])

    fig.update_layout(
        title_text=f"Inheritance graph — Top {len(filtered)} relationships (Top 10 parents)",
        height=900,
        width=1400,
        font=dict(size=10)
    )
    return fig



def analyze_package_structure(fqns):
    """Analyze package structure and return statistics and hierarchical data for Streamlit display."""
    if not fqns or len(fqns) == 0:
        return None

    clean_fqns = [str(f).strip() for f in fqns if str(f).strip() and str(f).strip() != 'nan']

    if not clean_fqns:
        return None

    stats = {
        'total_packages': len(clean_fqns),
        'unique_packages': len(set(clean_fqns)),
        'max_depth': max(fqn.count('.') + 1 for fqn in clean_fqns),
        'avg_depth': sum(fqn.count('.') + 1 for fqn in clean_fqns) / len(clean_fqns)
    }

    by_level = {}
    for fqn in clean_fqns:
        level = fqn.count('.') + 1
        if level not in by_level:
            by_level[level] = []
        by_level[level].append(fqn)

    root_packages = {}
    for fqn in clean_fqns:
        root = fqn.split('.')[0]
        root_packages[root] = root_packages.get(root, 0) + 1

    second_level = {}
    for fqn in clean_fqns:
        parts = fqn.split('.')
        if len(parts) >= 2:
            key = f"{parts[0]}.{parts[1]}"
            second_level[key] = second_level.get(key, 0) + 1

    tree_data = []
    for fqn in sorted(set(clean_fqns)):
        parts = fqn.split('.')
        tree_data.append({
            'Package FQN': fqn,
            'Root': parts[0],
            'Depth': len(parts),
            'Leaf Name': parts[-1]
        })

    return {
        'stats': stats,
        'by_level': by_level,
        'root_packages': root_packages,
        'second_level': second_level,
        'tree_data': tree_data
    }



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
    """Render Package Structure section for Streamlit using native components."""
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

    analysis = analyze_package_structure(fqns)

    if not analysis:
        st.info("Unable to analyze package structure.")
        return

    stats = analysis['stats']
    root_packages = analysis['root_packages']
    second_level = analysis['second_level']
    by_level = analysis['by_level']
    tree_data = analysis['tree_data']

    st.subheader("9A) Package Structure Overview")

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Packages", stats['total_packages'])
    with col2:
        st.metric("Unique Packages", stats['unique_packages'])
    with col3:
        st.metric("Max Depth", stats['max_depth'])
    with col4:
        st.metric("Avg Depth", f"{stats['avg_depth']:.1f}")

    st.divider()

    st.subheader("9B) Root Packages Distribution")
    root_df = pd.DataFrame([
        {'Root Package': k, 'Count': v}
        for k, v in sorted(root_packages.items(), key=lambda x: x[1], reverse=True)
    ])

    col1, col2 = st.columns([2, 1])
    with col1:
        st.dataframe(
            root_df,
            use_container_width=True,
            height=300,
            hide_index=True
        )
    with col2:
        st.markdown("**Summary**")
        st.markdown(f"- **Total root packages:** {len(root_packages)}")
        st.markdown(f"- **Most common:** {root_df.iloc[0]['Root Package']} ({root_df.iloc[0]['Count']})")
        if len(root_df) > 1:
            st.markdown(f"- **Second most:** {root_df.iloc[1]['Root Package']} ({root_df.iloc[1]['Count']})")

    st.divider()

    st.subheader("9C) Second Level Packages (Top 20)")
    second_level_df = pd.DataFrame([
        {'Package': k, 'Count': v}
        for k, v in sorted(second_level.items(), key=lambda x: x[1], reverse=True)[:20]
    ])

    if not second_level_df.empty:
        st.dataframe(
            second_level_df,
            use_container_width=True,
            height=400,
            hide_index=True
        )

    st.divider()

    st.subheader("9D) Packages by Depth Level")

    level_summary = []
    for level in sorted(by_level.keys()):
        level_summary.append({
            'Depth Level': level,
            'Package Count': len(by_level[level]),
            'Example': by_level[level][0] if by_level[level] else 'N/A'
        })

    level_df = pd.DataFrame(level_summary)
    st.dataframe(
        level_df,
        use_container_width=True,
        hide_index=True
    )

    st.divider()

    st.subheader("9E) Complete Package Hierarchy")
    st.markdown(f"**Total unique packages:** {len(tree_data)}")

    tree_df = pd.DataFrame(tree_data)
    st.dataframe(
        tree_df,
        use_container_width=True,
        height=500,
        hide_index=True
    )

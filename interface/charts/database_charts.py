import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import numpy as np
import ast
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent.parent))
from utils.helpers import labelize_na, find_col

MAX_BARS = 25  

def parse_listlike(x):
    """Return a list from cell x tolerant to JSON/Python lists or common separators."""
    if x is None or (isinstance(x, float) and np.isnan(x)):
        return []
    if isinstance(x, (list, tuple, set)):
        return [str(i).strip() for i in x if str(i).strip()]
    s = str(x).strip()
    if not s or s in {"N/A", "NA", "null", "None"}:
        return []
    if (s.startswith("[") and s.endswith("]")) or (s.startswith("(") and s.endswith(")")):
        try:
            val = ast.literal_eval(s)
            if isinstance(val, (list, tuple, set)):
                return [str(i).strip() for i in val if str(i).strip()]
        except Exception:
            pass
    for sep in [";", ",", "|"]:
        if sep in s:
            return [t.strip() for t in s.split(sep) if t.strip()]
    return [s]




def create_tables_treemap(df: pd.DataFrame, c_entity: str, c_table: str):
    """Create treemap for tables by number of mapped entities."""
    tmp = pd.DataFrame({
        "entity": df[c_entity].astype(str),
        "table": labelize_na(df[c_table]),
        "value": 1
    })
    agg = tmp.groupby("table")["value"].sum().reset_index(name="entities")

    fig = px.treemap(agg, path=["table"], values="entities",
                     title="Tables by Number of Mapped Entities (Treemap)")
    fig.update_layout(width=1000, height=600)
    return fig


def create_tables_bar(df: pd.DataFrame, c_entity: str, c_table: str):
    """Create bar chart for tables by number of mapped entities."""
    tmp = pd.DataFrame({
        "entity": df[c_entity].astype(str),
        "table": labelize_na(df[c_table]),
        "value": 1
    })
    agg = tmp.groupby("table")["value"].sum().reset_index(name="entities")
    top_tabs = agg.sort_values("entities", ascending=False).head(MAX_BARS)

    fig = px.bar(top_tabs, x="table", y="entities", text="entities",
                 title="Tables by Number of Mapped Entities (Bar)",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-45, width=1100, height=550,
                      xaxis_title="Table", yaxis_title="Entities")
    return fig




def create_top_annotations_bar(df: pd.DataFrame, c_entity: str, c_ann: str):
    """Create bar chart for top field annotations."""
    rows = []
    for _, r in df.iterrows():
        ent = str(r.get(c_entity, ""))
        for ann in parse_listlike(r.get(c_ann)):
            rows.append({"entity": ent, "annotation": ann})

    ann_df = pd.DataFrame(rows)

    if ann_df.empty:
        return None

    top_ann = (ann_df.groupby("annotation").size()
               .reset_index(name="count")
               .sort_values("count", ascending=False)
               .head(MAX_BARS))

    fig = px.bar(top_ann, x="annotation", y="count", text="count",
                 title="Top Field Annotations",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-40, width=1100, height=550,
                      xaxis_title="Annotation", yaxis_title="Count")
    return fig




def create_top_relationships_bar(df: pd.DataFrame, c_entity: str, c_rel: str):
    """Create bar chart for top entities by relationships."""
    rel_series = pd.to_numeric(df[c_rel], errors="coerce").fillna(0)
    df_rel = pd.DataFrame({
        "Entity": df[c_entity].astype(str),
        "Relationships": rel_series.astype(int)
    })

    top_rel = df_rel.sort_values("Relationships", ascending=False).head(MAX_BARS)

    fig = px.bar(top_rel, x="Entity", y="Relationships", text="Relationships",
                 title="Top Entities by Relationships",
                 color_discrete_sequence=["#1f77b4"])
    fig.update_traces(textposition="outside", cliponaxis=False)
    fig.update_layout(xaxis_tickangle=-45, width=1200, height=550,
                      xaxis_title="Entity", yaxis_title="Relationships")
    return fig


def create_relationships_histogram(df: pd.DataFrame, c_rel: str):
    """Create histogram for distribution of relationships per entity."""
    rel_series = pd.to_numeric(df[c_rel], errors="coerce").fillna(0)
    df_rel = pd.DataFrame({"Relationships": rel_series.astype(int)})

    fig = px.histogram(df_rel, x="Relationships", nbins=20,
                       title="Distribution of Relationships per Entity",
                       color_discrete_sequence=["#636EFA"])
    fig.update_layout(width=900, height=450, xaxis_title="Relationships", yaxis_title="Count")
    return fig




def create_entity_sankey(df: pd.DataFrame, c_from: str, c_to: str, c_rel: str):
    """Create Sankey diagram for Entity → Entity relationships."""
    e2e = df.dropna(subset=[c_from, c_to])

    if e2e.empty:
        return None

    g = e2e.groupby([c_from, c_to, c_rel]).size().reset_index(name="count")

    # Cap nodes by degree to keep legible
    deg = pd.concat([
        g.groupby(c_from)["count"].sum(),
        g.groupby(c_to)["count"].sum()
    ], axis=1).fillna(0).sum(axis=1)

    keep = set(deg.nlargest(80).index) if not deg.empty else set()
    g_c = g[g[c_from].isin(keep) & g[c_to].isin(keep)] if keep else g

    ents = sorted(set(g_c[c_from].astype(str)).union(set(g_c[c_to].astype(str))))

    if not ents:
        return None

    idx = {name: i for i, name in enumerate(ents)}
    src = [idx[s] for s in g_c[c_from].astype(str)]
    tgt = [idx[t] for t in g_c[c_to].astype(str)]
    val = g_c["count"].tolist()
    link_label = g_c[c_rel].astype(str).tolist()

    fig = go.Figure(data=[go.Sankey(
        arrangement="snap",
        node=dict(label=ents, pad=20, thickness=16),
        link=dict(source=src, target=tgt, value=val, label=link_label)
    )])
    fig.update_layout(title_text="Entity → Entity by Relation",
                      width=1200, height=700)
    return fig




def render_jpa_entities(df: pd.DataFrame):
    """Render JPA entities charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for JPA Entities analysis. The CSV file may be missing or empty.")
        return

    c_entity = find_col(df, "Entity", contains="entity", default="Entity")
    c_table = find_col(df, "TableName", contains="table", default=None)

    if c_table is None:
        st.warning("No TableName column found — skipping charts.")
        return

    st.subheader("1A) Tables by Number of Mapped Entities (Treemap)")
    fig = create_tables_treemap(df, c_entity, c_table)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("1B) Tables by Number of Mapped Entities (Bar)")
    fig = create_tables_bar(df, c_entity, c_table)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_entity_fields(df: pd.DataFrame):
    """Render entity fields (annotations) chart in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for Entity Fields analysis. The CSV file may be missing or empty.")
        return

    c_entity = find_col(df, "Entity", contains="entity", default="Entity")
    c_ann = find_col(df, "Annotations", contains="annotation", default=None)

    if c_ann is None:
        st.warning("No annotation-like column found — skipping chart.")
        return

    st.subheader("2A) Top Field Annotations")
    fig = create_top_annotations_bar(df, c_entity, c_ann)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No annotation entries parsed — skipping chart.")


def render_db_schema(df: pd.DataFrame):
    """Render DB schema (relationship statistics) charts in Streamlit."""
    import streamlit as st

    if df.empty:
        st.info("No data available for DB Schema analysis. The CSV file may be missing or empty.")
        return

    c_entity = find_col(df, "Entity", contains="entity", default="Entity")
    c_rel = find_col(df, "Relationships", contains="relationship", default=None)

    if c_rel is None:
        st.warning("No 'Relationships' column found — skipping stats.")
        return

    st.subheader("3A) Top Entities by Relationships")
    fig = create_top_relationships_bar(df, c_entity, c_rel)
    if fig:
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("3B) Distribution of Relationships per Entity")
    fig = create_relationships_histogram(df, c_rel)
    if fig:
        st.plotly_chart(fig, use_container_width=True)


def render_entity_relationships(df: pd.DataFrame):
    """Render entity relationship edges (Sankey) in Streamlit."""
    import streamlit as st

    # Treat header-only as empty
    if df.empty or len(df.dropna(how="all")) == 0 or len(df.columns) < 3:
        st.info("Entity Relationship Edges CSV missing or empty — nothing to plot.")
        return

    cols = {c.lower(): c for c in df.columns}
    c_from = cols.get("fromentity") or "fromEntity"
    c_to = cols.get("toentity") or "toEntity"
    c_rel = cols.get("relation") or "relation"

    if c_from not in df.columns or c_to not in df.columns:
        st.warning("Missing required columns (fromEntity, toEntity) — skipping Sankey.")
        return

    st.subheader("4A) Entity → Entity by Relation (Sankey)")
    fig = create_entity_sankey(df, c_from, c_to, c_rel)
    if fig:
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No edges after processing — skipping Sankey.")

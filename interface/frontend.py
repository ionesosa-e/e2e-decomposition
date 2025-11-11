import streamlit as st
import plotly.express as px
from pathlib import Path
import sys

sys.path.append(str(Path(__file__).parent))
from utils.helpers import read_csv_safe, get_csv_path
from charts.entry_points_charts import (
    render_main_classes_charts,
    render_spring_controllers_charts,
    render_spring_endpoints_charts
) 

st.set_page_config(page_title="Analysis decomposition insights", layout="wide")

st.title("🔍 Analysis decomposition insights")

stack, arch, entryPoints, db, dep, integration, fanInOut, sec, config, test = st.tabs(["| Technology Stack | ","| High Level Architecture | ", "| Entry Points |"
                            , "| Database |", "| Dependencies |", "| External Integration |"
                            , "| Fan In/Out |",  "| Security |", "| Configuration environment |", "| Testing |"])

with stack:
    st.header("Technology stack analysis")


with arch:
    st.header("High level architecture analysis")
    st.text("Prueba")
    st.text_area("Otra")
    st.warning("Que")
    sad = st.button("Advanced")

with entryPoints:
    st.header("Entry points and controller analysis")

    main_classes_tab, controllers_tab, endpoints_tab = st.tabs([
        "Main Classes",
        "Spring Controllers",
        "Spring Endpoints"
    ])

    with main_classes_tab:
        st.subheader("Main Classes Analysis")
        st.markdown("Distribution and analysis of classes with `main(String[])` methods.")

        csv_path = get_csv_path("API_Entry_Points", "Main_Classes.csv")
        df_main = read_csv_safe(csv_path)

        if not df_main.empty:
            with st.expander("View raw data"):
                st.dataframe(df_main.head(20))

            render_main_classes_charts(df_main)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with controllers_tab:
        st.subheader("Spring Controllers Analysis")
        st.markdown("Analysis of Spring `@Controller` and `@RestController` annotated classes.")

        csv_path = get_csv_path("API_Entry_Points", "Spring_Controller.csv")
        df_ctrl = read_csv_safe(csv_path)

        if not df_ctrl.empty:
            with st.expander("View raw data"):
                st.dataframe(df_ctrl.head(20))

            render_spring_controllers_charts(df_ctrl)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with endpoints_tab:
        st.subheader("Spring Endpoints Analysis")
        st.markdown("Analysis of REST endpoints exposed by Spring controllers.")

        csv_path = get_csv_path("API_Entry_Points", "Spring_Endpoints.csv")
        df_ep = read_csv_safe(csv_path)

        if not df_ep.empty:
            with st.expander("View raw data"):
                st.dataframe(df_ep.head(20))

            render_spring_endpoints_charts(df_ep)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

with db:
    st.header("Database analysis")

with dep:
    st.header("Dependency overview analysis")

with integration:
    st.header("Extneral integration analysis")

with fanInOut:
    st.header("Fan in and Fan out analysis")

with sec:
    st.header("Security overview analysis")

with config:
    st.header("Configuration environment analysis")

with test:
    st.header("Testing analysis")


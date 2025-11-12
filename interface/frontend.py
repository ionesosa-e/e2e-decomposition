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
from charts.configuration_environment_charts import (
    render_annotation_chart, 
    render_feature_flag_chart, 
    render_injected_properties_chart,
    render_extension_chart
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

    config_classes, config_files, feature_flags, injected_properties = st.tabs([
        "Configuration Classes",
        "Configuration Files",
        "Feature Flags",
        "Injected Properties"
    ])

    with config_classes:
        st.subheader("Configuration Classes Analysis")
        st.markdown("Distribution and analysis of classes with `configuration` annotations types.")

        csv_path = get_csv_path("Configuration_Environment", "Configuration_Classes.csv")
        df_main = read_csv_safe(csv_path)

        if not df_main.empty:
            with st.expander("View raw data"):
                st.dataframe(df_main.head(20))

            render_annotation_chart(df_main)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    
    with config_files:
        st.subheader("Configuration Files Analysis")
        st.markdown("Analysis of configuration files and their paths/extensions")

        csv_path = get_csv_path("Configuration_Environment", "Configuration_Files.csv")
        df_main = read_csv_safe(csv_path)

        if not df_main.empty:
            with st.expander("View raw data"):
                st.dataframe(df_main.head(20))

            render_extension_chart(df_main)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")


    with feature_flags:
        st.subheader("Feature Flags Analysis")
        st.markdown("Discovery and analysis of feature flags used in the application ")

        csv_path = get_csv_path("Configuration_Environment", "Feature_Flags.csv")
        df_main = read_csv_safe(csv_path)

        if not df_main.empty:
            with st.expander("View raw data"):
                st.dataframe(df_main.head(20))

            render_feature_flag_chart(df_main)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")


    with injected_properties:
        st.subheader("Injected Properties Analysis")
        st.markdown("Discovery and analysis of injected properties used in the application ")

        csv_path = get_csv_path("Configuration_Environment", "Injected_Properties.csv")
        df_main = read_csv_safe(csv_path)

        if not df_main.empty:
            with st.expander("View raw data"):
                st.dataframe(df_main.head(20))

            render_injected_properties_chart(df_main)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

with test:
    st.header("Testing analysis")
    st.warning("Testing queries were disabled for this analysis")


import streamlit as st
import plotly.express as px
import pandas as pd
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
from charts.high_level_architecture_charts import (
    render_layer_violations,
    render_cyclomatic_complexity,
    render_deepest_inheritance,
    render_excessive_dependencies,
    render_general_count_overview,
    render_god_classes,
    render_highest_methods,
    render_inheritance_between_classes,
    render_package_structure
)
from charts.dependencies_charts import (
    render_circular_dependencies,
    render_external_dependencies,
    render_lines_of_code,
    render_modules_and_artifacts,
    render_package_dependencies,
    render_package_dependencies_classes
)
from charts.database_charts import (
    render_jpa_entities,
    render_entity_fields,
    render_db_schema,
    render_entity_relationships
)
from charts.fan_in_fan_out_charts import (
    render_fan_in_fan_out
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

    code_quality_tab, code_smells_tab, overview_tab = st.tabs([
        "Code Quality",
        "Code Smells",
        "Overview"
    ])

    with code_quality_tab:
        st.markdown("### Architectural Layer Violations")
        csv_path = get_csv_path("High_Level_Architecture", "Architectural_Layer_Violation.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_layer_violations(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### Cyclomatic Complexity")
        csv_path = get_csv_path("High_Level_Architecture", "Cyclomatic_Complexity.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_cyclomatic_complexity(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### Deepest Inheritance")
        csv_path = get_csv_path("High_Level_Architecture", "Deepest_Inheritance.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_deepest_inheritance(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with code_smells_tab:
        st.markdown("### Excessive Dependencies")
        csv_path = get_csv_path("High_Level_Architecture", "Excessive_Dependencies.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_excessive_dependencies(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### God Classes")
        csv_path = get_csv_path("High_Level_Architecture", "God_Classes.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_god_classes(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### Highest Number of Methods")
        csv_path = get_csv_path("High_Level_Architecture", "Highest_Number_Methods_Class.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_highest_methods(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with overview_tab:
        st.markdown("### General Count Overview")
        csv_path = get_csv_path("High_Level_Architecture", "General_Count_Overview.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_general_count_overview(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### Inheritance Between Classes")
        csv_path = get_csv_path("High_Level_Architecture", "Inheritance_Between_Classes.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_inheritance_between_classes(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

        st.divider()

        st.markdown("### Package Structure")
        csv_path = get_csv_path("High_Level_Architecture", "Package_Structure.csv")
        df = read_csv_safe(csv_path)
        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))
            render_package_structure(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

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

    jpa_tab, fields_tab, schema_tab, relationships_tab = st.tabs([
        "JPA Entities",
        "Entity Fields",
        "DB Schema",
        "Entity Relationships"
    ])

    with jpa_tab:
        st.subheader("JPA Entities Analysis")
        st.markdown("Tables by number of mapped entities.")

        csv_path = get_csv_path("Database", "Jpa_Entities.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_jpa_entities(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with fields_tab:
        st.subheader("Entity Fields Analysis")
        st.markdown("Top field annotations across all entities.")

        csv_path = get_csv_path("Database", "Entity_Fields.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_entity_fields(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with schema_tab:
        st.subheader("DB Schema Analysis")
        st.markdown("Relationship statistics for database entities.")

        csv_path = get_csv_path("Database", "DB_Schema.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_db_schema(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with relationships_tab:
        st.subheader("Entity Relationships Analysis")
        st.markdown("Entity → Entity relationships visualized as a Sankey diagram.")

        csv_path = get_csv_path("Database", "Entity_Relationship_Edges.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_entity_relationships(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

with dep:
    st.header("Dependency overview analysis")

    circular_tab, external_tab, loc_tab, modules_tab, packages_tab, classes_tab = st.tabs([
        "Circular Dependencies",
        "External Dependencies",
        "Lines of Code",
        "Modules & Artifacts",
        "Package Dependencies",
        "Package Dependencies - Classes"
    ])

    with circular_tab:
        st.subheader("Circular Dependencies Analysis")
        st.markdown("Analysis of circular dependencies between packages.")

        csv_path = get_csv_path("Dependencies", "Circular_Dependencies.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_circular_dependencies(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with external_tab:
        st.subheader("External Dependencies Analysis")
        st.markdown("Overview of external dependencies (group → artifact).")

        csv_path = get_csv_path("Dependencies", "External_Dependencies.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_external_dependencies(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with loc_tab:
        st.subheader("Lines of Code Analysis")
        st.markdown("Top classes by lines of code and their distribution.")

        csv_path = get_csv_path("Dependencies", "Lines_Of_Code.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_lines_of_code(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with modules_tab:
        st.subheader("Modules & Artifacts Analysis")
        st.markdown("In/Out degree per artifact and top outgoing dependencies.")

        csv_path = get_csv_path("Dependencies", "Modules_And_Artifacts.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_modules_and_artifacts(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with packages_tab:
        st.subheader("Package Dependencies Analysis")
        st.markdown("Analysis of package-to-package dependencies (origin → destination).")

        csv_path = get_csv_path("Dependencies", "Package_Dependencies.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_package_dependencies(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

    with classes_tab:
        st.subheader("Package Dependencies - Classes Analysis")
        st.markdown("Top class-to-class dependency pairs by weight.")

        csv_path = get_csv_path("Dependencies", "Package_Dependencies_Classes.csv")
        df = read_csv_safe(csv_path)

        if not df.empty:
            with st.expander("View raw data"):
                st.dataframe(df.head(20))

            render_package_dependencies_classes(df)
        else:
            st.warning(f"No data available. Please ensure the CSV exists at: `{csv_path}`")

with integration:
    st.header("Extneral integration analysis")

with fanInOut:
    st.header("Fan in and Fan out analysis")
    st.markdown("""
    Fan-In measures how many classes depend on a given class (incoming dependencies).
    Fan-Out measures how many classes a given class depends on (outgoing dependencies).
    """)

    # Load both CSVs
    csv_path_in = get_csv_path("Fan_In_Fan_Out", "Fan_In.csv")
    csv_path_out = get_csv_path("Fan_In_Fan_Out", "Fan_Out.csv")

    df_in = read_csv_safe(csv_path_in)
    df_out = read_csv_safe(csv_path_out)

    if not df_in.empty or not df_out.empty:
        with st.expander("View raw data"):
            col1, col2 = st.columns(2)
            with col1:
                st.markdown("**Fan-In Data**")
                st.dataframe(df_in.head(20) if not df_in.empty else pd.DataFrame())
            with col2:
                st.markdown("**Fan-Out Data**")
                st.dataframe(df_out.head(20) if not df_out.empty else pd.DataFrame())

        render_fan_in_fan_out(df_in, df_out)
    else:
        st.warning(f"No data available. Please ensure the CSVs exist at: `{csv_path_in}` and `{csv_path_out}`")

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


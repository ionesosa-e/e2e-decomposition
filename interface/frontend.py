import streamlit as st
import plotly.express as px
#from ..jupyter/custom/API_Entry_Points import asd 

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


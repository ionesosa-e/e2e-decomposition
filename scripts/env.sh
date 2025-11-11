#!/usr/bin/env bash

# --- Versions ---
export NEO4J_EDITION="community"
export NEO4J_VERSION="2025.08.0"
export APOC_VERSION="2025.08.0"
export GDS_EDITION="open"            # open | full
export GDS_VERSION_OPEN="2.22.0"
export GDS_VERSION_FULL="2.22.0"
export JQASSISTANT_CLI_VERSION="2.8.0"

# --- Credentials ---
export NEO4J_INITIAL_PASSWORD="password1234"
export NEO4J_USER="neo4j"
export NEO4J_PASSWORD="$NEO4J_INITIAL_PASSWORD"

# --- Ports ---
export NEO4J_HTTP_PORT=7474
export NEO4J_HTTPS_PORT=7473
export NEO4J_BOLT_PORT=7687

# --- Portable project root (works in bash and zsh) ---
if [[ -n "${BASH_SOURCE:-}" ]]; then
  _SELF_PATH="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  _SELF_PATH="${(%):-%N}"
else
  _SELF_PATH="$0"
fi
export ROOT_DIRECTORY="$( cd "$( dirname -- "${_SELF_PATH}" )"/.. && pwd -P )"

# --- Paths (relative to repo root) ---
export TOOLS_DIRECTORY="${ROOT_DIRECTORY}/tools"
export DOWNLOADS_DIRECTORY="${ROOT_DIRECTORY}/downloads"
export NEO4J_DATA_DIRECTORY="${ROOT_DIRECTORY}/neo4j/data"
export NEO4J_RUNTIME_DIRECTORY="${ROOT_DIRECTORY}/runtime"
export NEO4J_IMPORT_DIRECTORY="${ROOT_DIRECTORY}/neo4j/import"
export NEO4J_CONF_DIRECTORY="${ROOT_DIRECTORY}/neo4j/conf"
export NEO4J_PLUGINS_DIRECTORY="${ROOT_DIRECTORY}/neo4j/plugins"

# --- Targets to analyze (jar-target) ---
export ARTIFACTS_DIRECTORY="${ROOT_DIRECTORY}/jar-target"
export REPO_TO_ANALYZE="${ARTIFACTS_DIRECTORY}"

# --- jQAssistant CLI download ---
export JQASSISTANT_CLI_ARTIFACT="jqassistant-commandline-neo4jv5"
export JQASSISTANT_CLI_DOWNLOAD_URL="https://repo1.maven.org/maven2/com/buschmais/jqassistant/cli"

# --- Output locations ---
export JQA_REPORT_DIR="${ROOT_DIRECTORY}/runtime/jqassistant/report"
export EXPORTS_DIR="${ROOT_DIRECTORY}/runtime/exports"

# --- Pipeline folders ---
export CYPHER_DIR="${ROOT_DIRECTORY}/cypher"
export REPORTS_DIR="${ROOT_DIRECTORY}/reports"
export CSV_REPORTS_DIRECTORY="${ROOT_DIRECTORY}/reports/csv-reports"
export JUPYTER_DIR="${ROOT_DIRECTORY}/jupyter"

# --- Neo4j/JQA homes ---
export NEO4J_HOME="${TOOLS_DIRECTORY}/neo4j-community-${NEO4J_VERSION}"
export JQA_HOME="${TOOLS_DIRECTORY}/${JQASSISTANT_CLI_ARTIFACT}-${JQASSISTANT_CLI_VERSION}"

# --- Connection strings ---
export NEO4J_URI="bolt://localhost:${NEO4J_BOLT_PORT}"
export NEO4J_HTTP_URL="http://localhost:${NEO4J_HTTP_PORT}"

# --- PATH ---
export PATH="${NEO4J_HOME}/bin:${JQA_HOME}/bin:${PATH}"

# --- Python/Jupyter ---
export VENV_DIR="${ROOT_DIRECTORY}/.venv"
export PIP_REQUIREMENTS="${ROOT_DIRECTORY}/requirements.txt"

# Notebook exports 
export ENABLE_NOTEBOOK_IPYNB="false"   
export ENABLE_NOTEBOOK_MD="false"      

# --- Basic guard ---
if [[ -z "${NEO4J_INITIAL_PASSWORD}" ]]; then
  echo "ERROR: NEO4J_INITIAL_PASSWORD is empty."; return 1 2>/dev/null || exit 1
fi

echo "Env loaded: Neo4j ${NEO4J_EDITION} ${NEO4J_VERSION}, APOC ${APOC_VERSION}, GDS(${GDS_EDITION}) ${GDS_VERSION_OPEN}/${GDS_VERSION_FULL}"
echo "Ports: HTTP ${NEO4J_HTTP_PORT}, HTTPS ${NEO4J_HTTPS_PORT}, BOLT ${NEO4J_BOLT_PORT}"
echo "Root: ${ROOT_DIRECTORY}"
echo "Cypher: ${CYPHER_DIR}  Reports: ${REPORTS_DIR}  Jupyter: ${JUPYTER_DIR}"
echo "NEO4J_HOME: ${NEO4J_HOME}  JQA_HOME: ${JQA_HOME}"



# Auto-instalar jq con Homebrew si falta
export E2E_AUTO_INSTALL_JQ="true"

# Saltar etapas
# export E2E_SKIP_SETUP="true"
# export E2E_SKIP_NEO4J="true"
# export E2E_SKIP_JQA="true"
# export E2E_SKIP_CSV="true"
# export E2E_SKIP_NOTEBOOKS="true"
# export E2E_STOP_NEO4J="true"
#!/usr/bin/env bash
# Runs a minimal centrality pipeline (GDS). Writes results and a summary CSV.

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

REPORT_NAME="centrality-csv"
OUT_DIR="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${OUT_DIR}"

CENTRALITY_DIR="${CYPHER_DIR}/Centrality"

echo "CentralityCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running GDS writes..."
# Write variants (no CSV expected), adjust as needed
execute_cypher "${CENTRALITY_DIR}/Centrality_3e_Page_Rank_Write.cypher"          > /dev/null || true
execute_cypher "${CENTRALITY_DIR}/Centrality_7e_Harmonic_Closeness_Write.cypher" > /dev/null || true
execute_cypher "${CENTRALITY_DIR}/Centrality_10e_Bridges_Write.cypher"           > /dev/null || true

echo "CentralityCsv: Exporting summary..."
execute_cypher "${CENTRALITY_DIR}/Centrality_90_Summary.cypher" > "${OUT_DIR}/CentralitySummary.csv" || true

echo "CentralityCsv: Done → ${OUT_DIR}"

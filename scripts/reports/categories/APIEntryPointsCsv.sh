#!/usr/bin/env bash
# Export API_Entry_Points → reports/API_Entry_Points

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"

source "${SCRIPTS_DIR}/cypher/cypher-helpers.sh"

SECTION="API_Entry_Points"
SRC_DIR="${CYPHER_DIR}/${SECTION}"
OUT_DIR="${CSV_REPORTS_DIRECTORY}/${SECTION}"

mkdir -p "${OUT_DIR}"

echo "APIEntryPointsCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Main_Classes.cypher"      > "${OUT_DIR}/Main_Classes.csv"
execute_cypher "${SRC_DIR}/Spring_Controller.cypher" > "${OUT_DIR}/Spring_Controller.csv"
execute_cypher "${SRC_DIR}/Spring_Endpoints.cypher"  > "${OUT_DIR}/Spring_Endpoints.csv"

echo "APIEntryPointsCsv: Done → ${OUT_DIR}"

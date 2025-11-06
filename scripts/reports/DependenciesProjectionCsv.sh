#!/usr/bin/env bash
# Runs "Dependencies_Projection" checks and mutations, then exports basic info.

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

REPORT_NAME="dependencies-projection-csv"
OUT_DIR="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${OUT_DIR}"

DEP_PROJ_DIR="${CYPHER_DIR}/Dependencies_Projection"

echo "DependenciesProjectionCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Checking projectable..."
# If the check returns rows, capture as CSV; if not, it will still run safely.
execute_cypher "${DEP_PROJ_DIR}/Dependencies_0_Check_Projectable.cypher" > "${OUT_DIR}/CheckProjectable.csv" || true

echo "DependenciesProjectionCsv: Mutating projection..."
execute_cypher "${DEP_PROJ_DIR}/Dependencies_9_Write_Mutated.cypher" > /dev/null || true

echo "DependenciesProjectionCsv: Done → ${OUT_DIR}"

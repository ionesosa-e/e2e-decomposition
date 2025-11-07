#!/usr/bin/env bash
# Export Custom_Queries/Security

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

SECTION="Security"
SRC_DIR="${CYPHER_DIR}/Custom_Queries/${SECTION}"
OUT_DIR="${REPORTS_DIRECTORY}/custom-queries-csv/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "SecurityCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Security_Configurations.cypher" > "${OUT_DIR}/Security_Configurations.csv"
execute_cypher "${SRC_DIR}/Spring_Security.cypher"         > "${OUT_DIR}/Spring_Security.csv"
execute_cypher "${SRC_DIR}/Unsecured_Endpoints.cypher"     > "${OUT_DIR}/Unsecured_Endpoints.csv"

echo "SecurityCsv: Done → ${OUT_DIR}"

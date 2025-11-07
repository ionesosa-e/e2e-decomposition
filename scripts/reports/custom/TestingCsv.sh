#!/usr/bin/env bash
# Export Custom_Queries/Testing

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

SECTION="Testing"
SRC_DIR="${CYPHER_DIR}/Custom_Queries/${SECTION}"
OUT_DIR="${REPORTS_DIRECTORY}/custom-queries-csv/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "TestingCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Test_Without_Assertion.cypher" > "${OUT_DIR}/Test_Without_Assertion.csv"

echo "TestingCsv: Done → ${OUT_DIR}"

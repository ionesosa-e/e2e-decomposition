#!/usr/bin/env bash
# Export Custom_Queries/Database

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

SECTION="Database"
SRC_DIR="${CYPHER_DIR}/Custom_Queries/${SECTION}"
OUT_DIR="${REPORTS_DIRECTORY}/custom-queries-csv/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "DatabaseCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/DB_Schema.cypher"    > "${OUT_DIR}/DB_Schema.csv"
execute_cypher "${SRC_DIR}/Entity_Fields.cypher" > "${OUT_DIR}/Entity_Fields.csv"
execute_cypher "${SRC_DIR}/Jpa_Entities.cypher"  > "${OUT_DIR}/Jpa_Entities.csv"

echo "DatabaseCsv: Done → ${OUT_DIR}"

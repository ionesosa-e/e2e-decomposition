#!/usr/bin/env bash

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/cypher/cypher-helpers.sh"

SECTION="Dependencies"
SRC_DIR="${CYPHER_DIR}/${SECTION}"
OUT_DIR="${CSV_REPORTS_DIRECTORY}/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "DependenciesCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Circular_Dependencies.cypher"        > "${OUT_DIR}/Circular_Dependencies.csv"
execute_cypher "${SRC_DIR}/External_Dependencies.cypher"        > "${OUT_DIR}/External_Dependencies.csv"
execute_cypher "${SRC_DIR}/External_Dependencies_Used_By_Scoped_Code.cypher" > "${OUT_DIR}/External_Dependencies_Used_By_Scoped_Code.csv"
execute_cypher "${SRC_DIR}/Lines_Of_Code.cypher"                > "${OUT_DIR}/Lines_Of_Code.csv"
execute_cypher "${SRC_DIR}/Modules_And_Artifacts.cypher"        > "${OUT_DIR}/Modules_And_Artifacts.csv"
execute_cypher "${SRC_DIR}/Package_Dependencies.cypher"         > "${OUT_DIR}/Package_Dependencies.csv"
execute_cypher "${SRC_DIR}/Package_Dependencies_Classes.cypher" > "${OUT_DIR}/Package_Dependencies_Classes.csv"

echo "DependenciesCsv: Done → ${OUT_DIR}"

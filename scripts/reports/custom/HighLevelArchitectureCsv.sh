#!/usr/bin/env bash
# Export Custom_Queries/High_Level_Architecture

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

SECTION="High_Level_Architecture"
SRC_DIR="${CYPHER_DIR}/Custom_Queries/${SECTION}"
OUT_DIR="${REPORTS_DIRECTORY}/custom-queries-csv/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "HighLevelArchitectureCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Architectural_Layer_Violation.cypher" > "${OUT_DIR}/Architectural_Layer_Violation.csv"
execute_cypher "${SRC_DIR}/Cyclomatic_Complexity.cypher"        > "${OUT_DIR}/Cyclomatic_Complexity.csv"
execute_cypher "${SRC_DIR}/Deepest_Inheritance.cypher"          > "${OUT_DIR}/Deepest_Inheritance.csv"
execute_cypher "${SRC_DIR}/Excessive_Dependencies.cypher"       > "${OUT_DIR}/Excessive_Dependencies.csv"
execute_cypher "${SRC_DIR}/General_Count_Overview.cypher"       > "${OUT_DIR}/General_Count_Overview.csv"
execute_cypher "${SRC_DIR}/God_Classes.cypher"                  > "${OUT_DIR}/God_Classes.csv"
execute_cypher "${SRC_DIR}/Highest_Number_Methods_Class.cypher" > "${OUT_DIR}/Highest_Number_Methods_Class.csv"
execute_cypher "${SRC_DIR}/Inheritance_Between_Classes.cypher"  > "${OUT_DIR}/Inheritance_Between_Classes.csv"
execute_cypher "${SRC_DIR}/Package_Structure.cypher"            > "${OUT_DIR}/Package_Structure.csv"

echo "HighLevelArchitectureCsv: Done → ${OUT_DIR}"

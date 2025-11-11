#!/usr/bin/env bash
set -euo pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/cypher/cypher-helpers.sh"

SECTION="Configuration_Environment"
SRC_DIR="${CYPHER_DIR}/${SECTION}"
OUT_DIR="${REPORTS_DIRECTORY}/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "ConfigurationEnvironmentCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Configuration_Classes.cypher"  > "${OUT_DIR}/Configuration_Classes.csv"
execute_cypher "${SRC_DIR}/Configuration_Files.cypher"    > "${OUT_DIR}/Configuration_Files.csv"
execute_cypher "${SRC_DIR}/Feature_Flags.cypher"          > "${OUT_DIR}/Feature_Flags.csv"
execute_cypher "${SRC_DIR}/Injected_Properties.cypher"    > "${OUT_DIR}/Injected_Properties.csv"

echo "ConfigurationEnvironmentCsv: Done → ${OUT_DIR}"

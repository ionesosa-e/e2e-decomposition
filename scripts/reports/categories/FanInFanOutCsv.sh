#!/usr/bin/env bash

set -o errexit -o pipefail
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/cypher/cypher-helpers.sh"

SECTION="Fan_In_Fan_Out"
SRC_DIR="${CYPHER_DIR}/${SECTION}"
OUT_DIR="${CSV_REPORTS_DIRECTORY}/${SECTION}"
mkdir -p "${OUT_DIR}"

echo "FanInFanOutCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running…"

execute_cypher "${SRC_DIR}/Fan_In.cypher"  > "${OUT_DIR}/Fan_In.csv"
execute_cypher "${SRC_DIR}/Fan_Out.cypher" > "${OUT_DIR}/Fan_Out.csv"

echo "FanInFanOutCsv: Done → ${OUT_DIR}"

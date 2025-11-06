#!/usr/bin/env bash
# Runs "Metrics" Cypher scripts. Mutations first, then CSV-producing queries.

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

REPORT_NAME="metrics-csv"
OUT_DIR="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${OUT_DIR}"

METRICS_DIR="${CYPHER_DIR}/Metrics"

echo "MetricsCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running mutations..."
# Mutations (no CSV output expected)
execute_cypher "${METRICS_DIR}/Calculate_and_set_Abstractness_for_Java.cypher" > /dev/null
execute_cypher "${METRICS_DIR}/Calculate_and_set_Abstractness_for_Java_including_Subpackages.cypher" > /dev/null || true
execute_cypher "${METRICS_DIR}/Calculate_and_set_Instability_for_Java.cypher" > /dev/null
execute_cypher "${METRICS_DIR}/Calculate_and_set_Instability_for_Java_Including_Subpackages.cypher" > /dev/null || true
execute_cypher "${METRICS_DIR}/Calculate_distance_between_abstractness_and_instability_for_Java.cypher" > /dev/null
execute_cypher "${METRICS_DIR}/Calculate_distance_between_abstractness_and_instability_for_Java_including_subpackages.cypher" > /dev/null || true
execute_cypher "${METRICS_DIR}/Set_Outgoing_Java_Package_Dependencies_Including_Subpackages.cypher" > /dev/null || true

echo "MetricsCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Exporting CSV..."
# CSV-producing queries (only those present in your tree)
execute_cypher "${METRICS_DIR}/Get_Incoming_Java_Package_Dependencies_Including_Subpackages.cypher" > "${OUT_DIR}/IncomingJavaPackageDependenciesIncludingSubpackages.csv"

echo "MetricsCsv: Done → ${OUT_DIR}"

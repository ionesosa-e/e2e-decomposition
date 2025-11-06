#!/usr/bin/env bash
# Runs "Java" Cypher queries and writes CSVs to reports/java-csv.

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

REPORT_NAME="java-csv"
OUT_DIR="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${OUT_DIR}"

JAVA_DIR="${CYPHER_DIR}/Java"

echo "JavaCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running queries..."

execute_cypher "${JAVA_DIR}/Java_Reflection_usage.cypher"                > "${OUT_DIR}/ReflectionUsage.csv"
execute_cypher "${JAVA_DIR}/Java_Reflection_usage_detailed.cypher"      > "${OUT_DIR}/ReflectionUsageDetailed.csv"
execute_cypher "${JAVA_DIR}/Java_deprecated_element_usage.cypher"       > "${OUT_DIR}/DeprecatedElementUsage.csv"
execute_cypher "${JAVA_DIR}/Java_deprecated_element_usage_detailed.cypher" > "${OUT_DIR}/DeprecatedElementUsageDetailed.csv"
execute_cypher "${JAVA_DIR}/Annotated_code_elements.cypher"             > "${OUT_DIR}/AnnotatedCodeElements.csv"
execute_cypher "${JAVA_DIR}/Annotated_code_elements_per_artifact.cypher"> "${OUT_DIR}/AnnotatedCodeElementsPerArtifact.csv"
execute_cypher "${JAVA_DIR}/JakartaEE_REST_Annotations.cypher"          > "${OUT_DIR}/JakartaEE_REST_Annotations.csv"
execute_cypher "${JAVA_DIR}/Spring_Web_Request_Annotations.cypher"      > "${OUT_DIR}/Spring_Web_Request_Annotations.csv"

echo "JavaCsv: Done → ${OUT_DIR}"

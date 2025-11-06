#!/usr/bin/env bash
# Runs "Community_Detection" writes and exports one CSV summary/query.

set -o errexit -o pipefail

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"}

REPORT_NAME="community-detection-csv"
OUT_DIR="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${OUT_DIR}"

COMMUNITY_DIR="${CYPHER_DIR}/Community_Detection"

echo "CommunityCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running community writes..."
execute_cypher "${COMMUNITY_DIR}/Community_Detection_2d_Leiden_Write_Node_Property.cypher"   > /dev/null || true
execute_cypher "${COMMUNITY_DIR}/Community_Detection_3e_WeaklyConnectedComponents_Write.cypher" > /dev/null || true

echo "CommunityCsv: Exporting CSV..."
execute_cypher "${COMMUNITY_DIR}/Which_package_community_spans_multiple_artifacts.cypher" > "${OUT_DIR}/WhichPackageCommunitySpansMultipleArtifacts.csv" || true

echo "CommunityCsv: Done → ${OUT_DIR}"

#!/usr/bin/env bash
# Runs the "Overview" Cypher queries and writes CSVs to reports/overview-csv.

set -o errexit -o pipefail

# Allow overriding the reports root
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

# Resolve key directories relative to this script:
# - This file lives in scripts/reports, so ".." is scripts, and "../.." is repo root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"

echo "OverviewCsv: SCRIPTS_DIR=${SCRIPTS_DIR}"
echo "OverviewCsv: CYPHER_DIR=${CYPHER_DIR}"

# Load helpers that expose: execute_cypher <file.cypher>
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

# Output folder
REPORT_NAME="overview-csv"
FULL_REPORT_DIRECTORY="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${FULL_REPORT_DIRECTORY}"

# Cypher source folder
OVERVIEW_CYPHER_DIR="${CYPHER_DIR}/Overview"

echo "OverviewCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running queries..."

execute_cypher "${OVERVIEW_CYPHER_DIR}/Node_label_count.cypher"                   > "${FULL_REPORT_DIRECTORY}/NodeLabelCount.csv"
execute_cypher "${OVERVIEW_CYPHER_DIR}/Relationship_type_count.cypher"            > "${FULL_REPORT_DIRECTORY}/RelationshipTypeCount.csv"
execute_cypher "${OVERVIEW_CYPHER_DIR}/Node_labels_and_their_relationships.cypher" > "${FULL_REPORT_DIRECTORY}/NodeLabelsAndRelationships.csv"
execute_cypher "${OVERVIEW_CYPHER_DIR}/Overview_size.cypher"                      > "${FULL_REPORT_DIRECTORY}/OverviewSize.csv"
execute_cypher "${OVERVIEW_CYPHER_DIR}/Number_of_packages_per_artifact.cypher"    > "${FULL_REPORT_DIRECTORY}/NumberOfPackagesPerArtifact.csv"
execute_cypher "${OVERVIEW_CYPHER_DIR}/Number_of_types_per_artifact.cypher"       > "${FULL_REPORT_DIRECTORY}/NumberOfTypesPerArtifact.csv"

echo "OverviewCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Done. Output → ${FULL_REPORT_DIRECTORY}"

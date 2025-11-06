#!/usr/bin/env bash
# Runs the "Artifact_Dependencies" Cypher queries and writes CSVs to reports/artifact-dependencies-csv.

set -o errexit -o pipefail

# Allow overriding the reports root
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

# Resolve key directories relative to this script:
# - This file lives in scripts/reports, so ".." is scripts, and "../.." is repo root.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"

echo "ArtifactDependenciesCsv: SCRIPTS_DIR=${SCRIPTS_DIR}"
echo "ArtifactDependenciesCsv: CYPHER_DIR=${CYPHER_DIR}"

# Load helpers that expose: execute_cypher <file.cypher>
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

# Output folder
REPORT_NAME="artifact-dependencies-csv"
FULL_REPORT_DIRECTORY="${REPORTS_DIRECTORY}/${REPORT_NAME}"
mkdir -p "${FULL_REPORT_DIRECTORY}"

# Cypher source folder
ARTIFACT_CYPHER_DIR="${CYPHER_DIR}/Artifact_Dependencies"

echo "ArtifactDependenciesCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Running queries..."

# Preparatory step (mutates aggregates used by downstream queries)
execute_cypher "${ARTIFACT_CYPHER_DIR}/Set_number_of_Java_packages_and_types_on_artifacts.cypher" > /dev/null

# CSV-producing queries
execute_cypher "${ARTIFACT_CYPHER_DIR}/Most_used_internal_dependencies_acreoss_artifacts.cypher" > "${FULL_REPORT_DIRECTORY}/MostUsedDependenciesAcrossArtifacts.csv"
execute_cypher "${ARTIFACT_CYPHER_DIR}/Artifacts_with_dependencies_to_other_artifacts.cypher"     > "${FULL_REPORT_DIRECTORY}/DependenciesAcrossArtifacts.csv"
execute_cypher "${ARTIFACT_CYPHER_DIR}/Artifacts_with_duplicate_packages.cypher"                  > "${FULL_REPORT_DIRECTORY}/DuplicatePackageNamesAcrossArtifacts.csv"
execute_cypher "${ARTIFACT_CYPHER_DIR}/Usage_and_spread_of_internal_artifact_dependencies.cypher" > "${FULL_REPORT_DIRECTORY}/InternalArtifactUsageSpreadPerDependency.csv"
execute_cypher "${ARTIFACT_CYPHER_DIR}/Usage_and_spread_of_internal_artifact_dependents.cypher"   > "${FULL_REPORT_DIRECTORY}/InternalArtifactUsageSpreadPerDependent.csv"

echo "ArtifactDependenciesCsv: $(date +'%Y-%m-%dT%H:%M:%S%z') Done. Output → ${FULL_REPORT_DIRECTORY}"

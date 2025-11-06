#!/usr/bin/env bash
# Runs the weight-enrichment for DEPENDS_ON relationships (no CSV output).

set -o errexit -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${SCRIPT_DIR}/.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
CYPHER_DIR="${REPO_ROOT}/cypher"
source "${SCRIPTS_DIR}/executeQueryFunctions.sh"

WEIGHTS_DIR="${CYPHER_DIR}/DependsOn_Relationship_Weights"

echo "DependsOnRelationshipWeights: $(date +'%Y-%m-%dT%H:%M:%S%z') Adding weights..."
execute_cypher "${WEIGHTS_DIR}/Add_weight10PercentInterfaces_to_Java_Package_DEPENDS_ON_relationships.cypher" > /dev/null || true

echo "DependsOnRelationshipWeights: Done."

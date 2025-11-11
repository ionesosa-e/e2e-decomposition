#!/usr/bin/env bash
set -euo pipefail

# Requires: source scripts/env.sh

ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
NEO4J_ED="${NEO4J_EDITION:?missing NEO4J_EDITION}"
NEO4J_VER="${NEO4J_VERSION:?missing NEO4J_VERSION}"
NEO4J_BOLT="${NEO4J_BOLT_PORT:?missing NEO4J_BOLT_PORT}"
NEO4J_USER_NAME="${NEO4J_USER:-neo4j}"
NEO4J_PWD="${NEO4J_PASSWORD:?missing NEO4J_PASSWORD}"

NEO4J_NAME="neo4j-${NEO4J_ED}-${NEO4J_VER}"
NEO4J_HOME="${NEO4J_HOME:-${TOOLS_DIR}/${NEO4J_NAME}}"
CSHELL="${NEO4J_HOME}/bin/cypher-shell"

[[ -x "${CSHELL}" ]] || { echo "cypher-shell not found. Install Neo4j first."; exit 1; }

# Prefer NEO4J_URI from env, fallback to localhost:bolt
CONN="${NEO4J_URI:-bolt://localhost:${NEO4J_BOLT}}"

run() {
  "${CSHELL}" --format=plain -a "${CONN}" -u "${NEO4J_USER_NAME}" -p "${NEO4J_PWD}" -d neo4j "$1"
}

echo "Checking connectivity..."
run "RETURN 1" >/dev/null
echo "OK: Bolt reachable."

echo "Checking APOC presence..."
APOC_COUNT=$(run "SHOW PROCEDURES YIELD name WHERE name STARTS WITH 'apoc.' RETURN count(*) AS c" | tail -n1 | tr -d '\r')
if [[ -z "${APOC_COUNT}" || "${APOC_COUNT}" == "0" ]]; then
  echo "ERROR: APOC not found. Verify plugin JAR and config." >&2
  exit 1
fi
APOC_VER=$(run "RETURN apoc.version() AS v" | tail -n1 | tr -d '\r')
echo "APOC version: ${APOC_VER}"

echo "Checking GDS presence..."
GDS_COUNT=$(run "SHOW PROCEDURES YIELD name WHERE name STARTS WITH 'gds.' RETURN count(*) AS c" | tail -n1 | tr -d '\r')
if [[ -z "${GDS_COUNT}" || "${GDS_COUNT}" == "0" ]]; then
  echo "ERROR: GDS not found. Verify plugin JAR and config." >&2
  exit 1
fi

GDS_VER=$(run "RETURN gds.version() AS version" | tail -n1 | tr -d '\r')
if [[ -z "${GDS_VER}" || "${GDS_VER}" == "(no data)" ]]; then
  GDS_VER="unknown"
fi
echo "GDS version: ${GDS_VER}"

echo "Smoke test passed."

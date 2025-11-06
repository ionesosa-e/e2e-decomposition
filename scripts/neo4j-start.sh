#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
NEO4J_ED="${NEO4J_EDITION:?missing NEO4J_EDITION}"
NEO4J_VER="${NEO4J_VERSION:?missing NEO4J_VERSION}"
NEO4J_HTTP="${NEO4J_HTTP_PORT:?missing NEO4J_HTTP_PORT}"
NEO4J_BOLT="${NEO4J_BOLT_PORT:?missing NEO4J_BOLT_PORT}"

NEO4J_NAME="neo4j-${NEO4J_ED}-${NEO4J_VER}"
NEO4J_HOME="${TOOLS_DIR}/${NEO4J_NAME}"
NEO4J_BIN="${NEO4J_HOME}/bin"

wait_bolt() {
  for _ in {1..60}; do
    if nc -z localhost "${NEO4J_BOLT}" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

# If Bolt already reachable, do nothing
if nc -z localhost "${NEO4J_BOLT}" >/dev/null 2>&1; then
  echo "Neo4j already running at ${NEO4J_HOME}"
  echo "HTTP: http://localhost:${NEO4J_HTTP}  BOLT: bolt://localhost:${NEO4J_BOLT}"
  exit 0
fi

echo "Starting Neo4j..."
set +e
NEO4J_HOME="${NEO4J_HOME}" "${NEO4J_BIN}/neo4j" start
rc=$?
set -e

# If start failed because port was in use, but Bolt is now up, treat as ok
if [[ $rc -ne 0 ]]; then
  if wait_bolt; then
    echo "Bolt is up; treating previous start error as benign (already running)."
  else
    echo "Neo4j failed to start. Check logs in runtime/logs/."
    exit $rc
  fi
else
  wait_bolt || { echo "Bolt not reachable after start."; exit 1; }
fi

echo "HTTP: http://localhost:${NEO4J_HTTP}  BOLT: bolt://localhost:${NEO4J_BOLT}"

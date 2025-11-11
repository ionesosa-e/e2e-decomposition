#!/usr/bin/env bash
set -euo pipefail

# Requires: source scripts/env.sh

ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
NEO4J_ED="${NEO4J_EDITION:?missing NEO4J_EDITION}"
NEO4J_VER="${NEO4J_VERSION:?missing NEO4J_VERSION}"
NEO4J_HTTP="${NEO4J_HTTP_PORT:?missing NEO4J_HTTP_PORT}"
NEO4J_BOLT="${NEO4J_BOLT_PORT:?missing NEO4J_BOLT_PORT}"

NEO4J_NAME="neo4j-${NEO4J_ED}-${NEO4J_VER}"
NEO4J_HOME="${NEO4J_HOME:-${TOOLS_DIR}/${NEO4J_NAME}}"
NEO4J_BIN="${NEO4J_HOME}/bin"

have_nc() { command -v nc >/dev/null 2>&1; }
is_darwin() { [[ "$(uname)" == "Darwin" ]]; }

# Quick listener check (no blocking)
port_in_use() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:${NEO4J_BOLT} -sTCP:LISTEN -n -P >/dev/null 2>&1
  elif have_nc; then
    if is_darwin; then nc -z -G 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; else nc -z -w 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; fi
  else
    return 1
  fi
}

# Wait for Bolt with short timeouts
wait_bolt() {
  for _ in {1..60}; do
    if have_nc; then
      if is_darwin; then
        if nc -z -G 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; then return 0; fi
      else
        if nc -z -w 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; then return 0; fi
      fi
    else
      if port_in_use; then return 0; fi
    fi
    sleep 1
  done
  return 1
}

# 1) Our Neo4j already running?
if "${NEO4J_BIN}/neo4j" status | grep -qi "running"; then
  echo "Neo4j already running at ${NEO4J_HOME}"
  echo "HTTP: http://localhost:${NEO4J_HTTP}  BOLT: bolt://localhost:${NEO4J_BOLT}"
  exit 0
fi

# 2) If not running but port is busy, it's a conflict.
if port_in_use; then
  echo "ERROR: Port ${NEO4J_BOLT} is in use by another process (not ${NEO4J_HOME})."
  command -v lsof >/dev/null 2>&1 && lsof -iTCP:${NEO4J_BOLT} -sTCP:LISTEN -n -P || true
  exit 2
fi

echo "Starting Neo4j..."
set +e
NEO4J_HOME="${NEO4J_HOME}" "${NEO4J_BIN}/neo4j" start
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  if wait_bolt; then
    echo "Bolt is up; treating previous start error as benign."
  else
    echo "Neo4j failed to start."
    exit $rc
  fi
else
  wait_bolt || { echo "Bolt not reachable after start."; exit 1; }
fi

echo "HTTP: http://localhost:${NEO4J_HTTP}  BOLT: bolt://localhost:${NEO4J_BOLT}"

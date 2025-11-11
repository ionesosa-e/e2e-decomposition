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

# Non-blocking port check
is_up() {
  if have_nc; then
    if is_darwin; then nc -z -G 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; else nc -z -w 1 localhost "${NEO4J_BOLT}" >/dev/null 2>&1; fi
  else
    # Fallback: best-effort check without nc (may fail on some shells)
    (echo > "/dev/tcp/localhost/${NEO4J_BOLT}") >/dev/null 2>&1
  fi
}

pid_on_port() { lsof -t -i:"$1" -sTCP:LISTEN 2>/dev/null || true; }

if ! is_up; then
  echo "Neo4j already stopped."
  exit 0
fi

echo "Stopping Neo4j at ${NEO4J_HOME}..."
set +e
NEO4J_HOME="${NEO4J_HOME}" "${NEO4J_BIN}/neo4j" stop
set -e

# Fallback: if still listening, kill the PID(s) on the Bolt port
if is_up; then
  PIDS="$(pid_on_port "${NEO4J_BOLT}")"
  if [[ -n "${PIDS}" ]]; then
    echo "Force-stopping process(es) on port ${NEO4J_BOLT}: ${PIDS}"
    kill ${PIDS} || true
    sleep 2
    PIDS="$(pid_on_port "${NEO4J_BOLT}")"
    if [[ -n "${PIDS}" ]]; then
      kill -9 ${PIDS} || true
    fi
  fi
fi

# Wait until Bolt closes (max 30s)
for _ in {1..30}; do
  if ! is_up; then
    echo "Neo4j stopped."
    exit 0
  fi
  sleep 1
done

echo "WARNING: Bolt still listening on :${NEO4J_BOLT}. Check processes manually."
exit 1

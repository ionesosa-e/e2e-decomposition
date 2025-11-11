#!/usr/bin/env bash
# Helper functions to execute Cypher files via Neo4j HTTP API using scripts/cypher/cypher-run-query.sh
# Deps: cypher-run-query.sh, curl, jq
# Requires: NEO4J_INITIAL_PASSWORD env var

set -o errexit -o pipefail

# --- Locate this script's directory ---
HELPER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${HELPER_DIR}/.." && pwd -P )"

# --- Defaults (override via env in caller) ---
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

# Root for Cypher files: <repo>/cypher (use env if present; else resolve two levels up)
CYPHER_DIR=${CYPHER_DIR:-"${HELPER_DIR}/../../cypher"}

# HTTP settings (reused by cypher-run-query.sh)
NEO4J_HTTP_PORT=${NEO4J_HTTP_PORT:-"7474"}
NEO4J_HTTP_TRANSACTION_ENDPOINT=${NEO4J_HTTP_TRANSACTION_ENDPOINT:-"db/neo4j/tx/commit"}

# Binary to execute queries (co-located with this helper)
EXECUTE_QUERY_BIN="${HELPER_DIR}/cypher-run-query.sh"

# --- Internal guard ---
if [[ ! -x "${EXECUTE_QUERY_BIN}" ]]; then
  echo "ERROR: Missing or non-executable ${EXECUTE_QUERY_BIN}. Run: chmod +x ${EXECUTE_QUERY_BIN}" >&2
  exit 1
fi

# --- Helpers ---

# Normalize a path: if it's relative (starts without /), prefix CYPHER_DIR
_resolve_cypher_path() {
  local q="$1"
  if [[ -z "$q" ]]; then
    echo "ERROR: _resolve_cypher_path: empty path" >&2
    return 1
  fi
  if [[ -f "$q" ]]; then
    echo "$q"
    return 0
  fi
  if [[ -f "${CYPHER_DIR}/${q}" ]]; then
    echo "${CYPHER_DIR}/${q}"
    return 0
  fi
  local stripped="${q#cypher/}"
  if [[ -f "${CYPHER_DIR}/${stripped}" ]]; then
    echo "${CYPHER_DIR}/${stripped}"
    return 0
  fi
  echo "ERROR: Cypher file not found: $q (searched also under ${CYPHER_DIR})" >&2
  return 1
}

execute_cypher() {
  local cypher_path
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  # shellcheck disable=SC2068
  "${EXECUTE_QUERY_BIN}" "${cypher_path}" $@
}

execute_cypher_no_src() {
  local cypher_path
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" $@
}

execute_cypher_md() {
  local cypher_path
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --output-markdown-table "${cypher_path}" $@
}

# Returns number of data rows (excludes header)
execute_cypher_http_number_of_lines_in_result() {
  local cypher_path out_csv lines
  cypher_path=$(_resolve_cypher_path "$1")
  if ! out_csv=$("${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" 2>/dev/null); then
    echo "0"; return 0
  fi
  lines=$(echo -n "${out_csv}" | wc -l | tr -d ' ')
  if [[ "${lines}" -ge 1 ]]; then echo $((lines - 1)); else echo "0"; fi
}

ensure_dir() {
  mkdir -p "$1"
}

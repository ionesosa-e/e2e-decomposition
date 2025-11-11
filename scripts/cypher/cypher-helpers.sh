#!/usr/bin/env bash
set -euo pipefail

# Resolve this script dir
HELPER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"

REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}
CYPHER_DIR=${CYPHER_DIR:-"${HELPER_DIR}/../../cypher"}

NEO4J_HTTP_PORT=${NEO4J_HTTP_PORT:-"7474"}
NEO4J_HTTP_TRANSACTION_ENDPOINT=${NEO4J_HTTP_TRANSACTION_ENDPOINT:-"db/neo4j/tx/commit"}

EXECUTE_QUERY_BIN="${HELPER_DIR}/cypher-run-query.sh"
[[ -x "${EXECUTE_QUERY_BIN}" ]] || { echo "ERROR: Missing or non-executable ${EXECUTE_QUERY_BIN}"; exit 1; }

# Path resolver
_resolve_cypher_path() {
  local q="$1"
  [[ -n "$q" ]] || { echo "ERROR: empty path" >&2; return 1; }
  [[ -f "$q" ]] && { echo "$q"; return 0; }
  [[ -f "${CYPHER_DIR}/${q}" ]] && { echo "${CYPHER_DIR}/${q}"; return 0; }
  local stripped="${q#cypher/}"
  [[ -f "${CYPHER_DIR}/${stripped}" ]] && { echo "${CYPHER_DIR}/${stripped}"; return 0; }
  echo "ERROR: Cypher file not found: $q (searched under ${CYPHER_DIR})" >&2; return 1
}

execute_cypher() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" "${cypher_path}" "$@"
}

execute_cypher_no_src() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" "$@"
}

execute_cypher_md() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --output-markdown-table "${cypher_path}" "$@"
}

execute_cypher_http_number_of_lines_in_result() {
  local cypher_path out_csv lines
  cypher_path=$(_resolve_cypher_path "$1")
  if ! out_csv=$("${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" 2>/dev/null); then echo "0"; return 0; fi
  lines=$(echo -n "${out_csv}" | wc -l | tr -d ' ')
  if [[ "${lines}" -ge 1 ]]; then echo $((lines - 1)); else echo "0"; fi
}

ensure_dir() { mkdir -p "$1"; }

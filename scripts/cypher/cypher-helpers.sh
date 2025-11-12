#!/usr/bin/env bash
set -euo pipefail

# This helper centralizes Cypher execution and parameter passing.
# It injects scopePackage=<SCOPE_PACKAGE> unless the caller already provided scopePackage=...
# Code and comments in English.

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

ensure_dir() { mkdir -p "$1"; }

# --- Internal: append scope parameter if missing (bash 3.2-friendly) ----------
# Note: Implemented inline in wrappers to avoid nameref/local -n (unsupported on bash 3.2).
# -----------------------------------------------------------------------------

execute_cypher() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  local params=("$@")

  # Append scopePackage unless already provided by the caller
  local add_scope="true" p
  for p in "${params[@]:-}"; do
    if [[ "$p" == scopePackage=* ]]; then
      add_scope="false"; break
    fi
  done
  if [[ "$add_scope" == "true" ]]; then
    params+=("scopePackage=${SCOPE_PACKAGE:-}")
  fi

  "${EXECUTE_QUERY_BIN}" "${cypher_path}" "${params[@]}"
}

execute_cypher_no_src() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  local params=("$@")

  local add_scope="true" p
  for p in "${params[@]:-}"; do
    if [[ "$p" == scopePackage=* ]]; then
      add_scope="false"; break
    fi
  done
  if [[ "$add_scope" == "true" ]]; then
    params+=("scopePackage=${SCOPE_PACKAGE:-}")
  fi

  "${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" "${params[@]}"
}

execute_cypher_md() {
  local cypher_path; cypher_path=$(_resolve_cypher_path "$1"); shift || true
  local params=("$@")

  local add_scope="true" p
  for p in "${params[@]:-}"; do
    if [[ "$p" == scopePackage=* ]]; then
      add_scope="false"; break
    fi
  done
  if [[ "$add_scope" == "true" ]]; then
    params+=("scopePackage=${SCOPE_PACKAGE:-}")
  fi

  "${EXECUTE_QUERY_BIN}" --output-markdown-table "${cypher_path}" "${params[@]}"
}

execute_cypher_http_number_of_lines_in_result() {
  # Note: This helper does a raw count and intentionally does not inject scope parameters.
  # If you need scoped counting, prefer calling execute_cypher and count externally.
  local cypher_path out_csv lines
  cypher_path=$(_resolve_cypher_path "$1")
  if ! out_csv=$("${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" 2>/dev/null); then
    echo "0"; return 0
  fi
  lines=$(echo -n "${out_csv}" | wc -l | tr -d ' ')
  if [[ "${lines}" -ge 1 ]]; then echo $((lines - 1)); else echo "0"; fi
}

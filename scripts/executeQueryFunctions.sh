#!/usr/bin/env bash
# Helper functions to execute Cypher files via Neo4j HTTP API using scripts/executeQuery.sh
# Deps: scripts/executeQuery.sh, curl, jq
# Requires: NEO4J_INITIAL_PASSWORD env var

set -o errexit -o pipefail

# --- Locate this scripts directory (portable) ---
SCRIPTS_DIR=${SCRIPTS_DIR:-$( CDPATH=. cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P )}

# --- Defaults (override via env in caller) ---
# Where CSV/MD reports will be written by report scripts (they control redirections)
REPORTS_DIRECTORY=${REPORTS_DIRECTORY:-"reports"}

# Root for Cypher files. Por convención usamos <repo>/cypher
CYPHER_DIR=${CYPHER_DIR:-"${SCRIPTS_DIR}/../cypher"}

# HTTP settings (reutilizados por executeQuery.sh)
NEO4J_HTTP_PORT=${NEO4J_HTTP_PORT:-"7474"}
NEO4J_HTTP_TRANSACTION_ENDPOINT=${NEO4J_HTTP_TRANSACTION_ENDPOINT:-"db/neo4j/tx/commit"}

# --- Internal guard ---
EXECUTE_QUERY_BIN="${SCRIPTS_DIR}/executeQuery.sh"
if [[ ! -x "${EXECUTE_QUERY_BIN}" ]]; then
  echo "ERROR: Missing or non-executable ${EXECUTE_QUERY_BIN}. Run: chmod +x ${EXECUTE_QUERY_BIN}" >&2
  exit 1
fi

# --- Helpers ---

# Normalize a path: if it's relative (starts without /), prefix CYPHER_DIR
# Allows calling: execute_cypher "Overview/Node_label_count.cypher" OR "cypher/Overview/Node_label_count.cypher"
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
  # try under CYPHER_DIR
  if [[ -f "${CYPHER_DIR}/${q}" ]]; then
    echo "${CYPHER_DIR}/${q}"
    return 0
  fi
  # try stripping leading "cypher/"
  local stripped="${q#cypher/}"
  if [[ -f "${CYPHER_DIR}/${stripped}" ]]; then
    echo "${CYPHER_DIR}/${stripped}"
    return 0
  fi
  echo "ERROR: Cypher file not found: $q (searched also under ${CYPHER_DIR})" >&2
  return 1
}

# Execute a Cypher file -> CSV to stdout (adds trailing "Source Cypher File" column)
# Usage: execute_cypher "Overview/Node_label_count.cypher"
#        execute_cypher "Overview/Node_label_count.cypher" project=myapp top=50
execute_cypher() {
  local cypher_path params
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  # shellcheck disable=SC2068 # we intentionally pass raw key=value pairs
  "${EXECUTE_QUERY_BIN}" "${cypher_path}" $@
}

# Same as execute_cypher but WITHOUT the source reference column
execute_cypher_no_src() {
  local cypher_path params
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" $@
}

# Execute and render as Markdown table (useful para docs/Jupyter exportados)
execute_cypher_md() {
  local cypher_path params
  cypher_path=$(_resolve_cypher_path "$1"); shift || true
  "${EXECUTE_QUERY_BIN}" --output-markdown-table "${cypher_path}" $@
}

# Return number of data rows (excluye header) — útil para validaciones previas a ejecutar notebooks
# Devuelve un número por stdout. Si falla la query, retorna 0 por seguridad (y deja que el caller decida).
execute_cypher_http_number_of_lines_in_result() {
  local cypher_path
  cypher_path=$(_resolve_cypher_path "$1")
  # Emitimos CSV y contamos líneas – 1 (header). Si no hay datos → 0.
  if ! out_csv=$("${EXECUTE_QUERY_BIN}" --no-source-reference-column "${cypher_path}" 2>/dev/null); then
    echo "0"
    return 0
  fi
  # wc -l cuenta líneas; restamos 1 por header si hay al menos 1 línea
  local lines
  lines=$(echo -n "${out_csv}" | wc -l | tr -d ' ')
  if [[ "${lines}" -ge 1 ]]; then
    echo $((lines - 1))
  else
    echo "0"
  fi
}

# Convenience: ensure dir exists (call this in report scripts before writing files)
ensure_dir() {
  mkdir -p "$1"
}

#!/usr/bin/env bash
# Executes a Cypher query file via Neo4j HTTP API and prints CSV (or Markdown).
# Deps: curl, jq. Requires: NEO4J_INITIAL_PASSWORD env var.

set -o errexit -o pipefail

# ---------- Defaults (override via env) ----------
NEO4J_HTTP_PORT=${NEO4J_HTTP_PORT:-"7474"}
# Neo4j v5 endpoint; adjust if DB name != "neo4j"
NEO4J_HTTP_TRANSACTION_ENDPOINT=${NEO4J_HTTP_TRANSACTION_ENDPOINT:-"db/neo4j/tx/commit"}

# ---------- Local ----------
ERROR_COLOR='\033[0;31m'
NO_COLOR='\033[0m'

print_usage() {
  echo "Usage: $0 <cypher_file> [--no-source-reference-column] [--omit-query-error-highlighting] [--output-markdown-table] [key=value ...]" >&2
}

# ---------- Preflight ----------
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found."; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found."; exit 1; }

if [ -z "${NEO4J_INITIAL_PASSWORD}" ]; then
  echo "ERROR: NEO4J_INITIAL_PASSWORD not set. e.g. 'export NEO4J_INITIAL_PASSWORD=password1234'." >&2
  exit 1
fi

# ---------- Args ----------
cypher_file=""
no_source_reference=false
omit_query_error_highlighting=false
output_markdown_table=false
query_parameters=""

while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --no-source-reference-column) no_source_reference=true; shift ;;
    --omit-query-error-highlighting) omit_query_error_highlighting=true; shift ;;
    --output-markdown-table) output_markdown_table=true; shift ;;
    *)
      if [[ -z "$cypher_file" ]]; then
        cypher_file="$arg"
        if [[ ! -f "$cypher_file" ]]; then
          echo "ERROR: Cypher file not found: $cypher_file" >&2
          print_usage; exit 1
        fi
        shift
      else
        # accept key=value params → JSON "key":"value" (strip quotes)
        json_param=$(echo "$arg" | sed "s/[\"\']//g" | awk -F'=' '{ print "\""$1"\": \""$2"\"" }' | grep -iv '\"#' || true)
        if [[ -n "$json_param" ]]; then
          if [[ -z "$query_parameters" ]]; then
            query_parameters="$json_param"
          else
            query_parameters="$query_parameters, $json_param"
          fi
        fi
        shift
      fi
      ;;
  esac
done

if [[ -z "$cypher_file" ]]; then
  print_usage; exit 1
fi

# ---------- Colors ----------
err_color="${ERROR_COLOR}"
$omit_query_error_highlighting && err_color="${NO_COLOR}"

# ---------- Read & encode query ----------
original_query=$(<"$cypher_file")
# JSON-escape multi-line query
query_json=$(echo -n "${original_query}" | jq -Rsa .)

payload="{\"statements\":[{\"statement\":${query_json},\"parameters\":{${query_parameters}},\"includeStats\":false}]}"

# ---------- Call Neo4j HTTP API ----------
if ! response=$(curl --silent -S --fail-with-body \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -u neo4j:"${NEO4J_INITIAL_PASSWORD}" \
  "http://localhost:${NEO4J_HTTP_PORT}/${NEO4J_HTTP_TRANSACTION_ENDPOINT}" \
  -d "${payload}" 2>&1); then
  echo -e "${err_color}${cypher_file}: ${response}${NO_COLOR}" >&2
  echo -e "${err_color}Parameters: ${query_parameters}${NO_COLOR}" >&2
  exit 1
fi

# ---------- Handle errors from Neo4j ----------
error_obj=$(echo "${response}" | jq -r '.errors[0] // empty')
if [[ -n "${error_obj}" && "${error_obj}" != "null" ]]; then
  echo -e "${err_color}${cypher_file}: ${error_obj}${NO_COLOR}" >&2
  echo -e "${err_color}Parameters: ${query_parameters}${NO_COLOR}" >&2
  exit 1
fi

# ---------- Output ----------
if $output_markdown_table; then
  # Minimal Markdown table (header + rows)
  # columns: .results[0].columns ; rows: .results[0].data[].row
  echo "${response}" | jq -r '
    .results[0] as $r
    | ($r.columns) as $cols
    | ("| " + ($cols | join(" | ")) + " |\n| " + ([$cols[] | "---"] | join(" | ")) + " |")
    + ("\n" + ($r.data[]
        | .row
        | (map(if type=="array" then (join(",")) else tostring end) | join(" | "))
        | "| " + . + " |"
      ) // "" )
  '
else
  if $no_source_reference; then
    echo -n "${response}" \
      | jq -r '(.results[0])? | .columns,(.data[].row)? | map(if type == "array" then join(",") else . end) | flatten | @csv'
  else
    cypher_rel="${cypher_file#/**/cypher/}"
    src_ref="Source Cypher File: ${cypher_rel}"
    echo -n "${response}" \
      | jq -r --arg sourceReference "${src_ref}" \
        '(.results[0])? | .columns + [$sourceReference], (.data[].row)? + [""] | map(if type == "array" then join(",") else . end) | flatten | @csv'
  fi
fi

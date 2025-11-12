#!/usr/bin/env bash
# Re-exports env vars from config/analysis-scope.json without modifying scripts/env.sh.
# If JSON defines:
#   - "input_path": overrides REPO_TO_ANALYZE
#   - "output_path": overrides REPORTS_DIR
#     and (if not already set) CSV_REPORTS_DIRECTORY = <output>/csv-reports
# No changes are applied when the JSON is missing or the keys are empty.

set -euo pipefail

# Resolve repo root (works in bash and zsh)
if [[ -n "${BASH_SOURCE:-}" ]]; then
  _SELF="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  _SELF="${(%):-%N}"
else
  _SELF="$0"
fi
SCRIPT_DIR="$(cd "$(dirname -- "$_SELF")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
CFG="$REPO_ROOT/config/analysis-scope.json"

# Lightweight JSON reader (prefers jq; falls back to a simple grep/sed)
_read_json_value() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -er --arg k "$key" 'if has($k) and (.[$k] != null) and (.[$k] != "") then .[$k] else empty end' "$CFG" 2>/dev/null || true
    return 0
  fi
  grep -E "\"$key\"[[:space:]]*:" "$CFG" 2>/dev/null \
    | head -n1 \
    | sed -E 's/.*"'$key'":[[:space:]]*"(.*)".*/\1/' \
    | sed -E 's/[[:space:]]+$//' || true
}

log() { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }

# No JSON → no-op
if [[ ! -f "$CFG" ]]; then
  log "analysis-scope.json not found → no overrides applied"
  return 0 2>/dev/null || exit 0
fi

INPUT_PATH="$(_read_json_value "input_path")"
OUTPUT_PATH="$(_read_json_value "output_path")"

# Apply overrides only when provided in JSON
if [[ -n "${INPUT_PATH:-}" ]]; then
  export REPO_TO_ANALYZE="$INPUT_PATH"
  log "Override: REPO_TO_ANALYZE=$REPO_TO_ANALYZE"
fi

if [[ -n "${OUTPUT_PATH:-}" ]]; then
  export REPORTS_DIR="$OUTPUT_PATH"
  log "Override: REPORTS_DIR=$REPORTS_DIR"

  if [[ -z "${CSV_REPORTS_DIRECTORY:-}" ]]; then
    export CSV_REPORTS_DIRECTORY="$REPORTS_DIR/csv-reports"
    log "Derived: CSV_REPORTS_DIRECTORY=$CSV_REPORTS_DIRECTORY"
  else
    log "Preserving existing CSV_REPORTS_DIRECTORY=$CSV_REPORTS_DIRECTORY"
  fi
fi

return 0 2>/dev/null || exit 0

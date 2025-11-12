#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (bash/zsh)
if [[ -n "${BASH_SOURCE:-}" ]]; then _SELF="${BASH_SOURCE[0]}"; elif [[ -n "${ZSH_VERSION:-}" ]]; then _SELF="${(%):-%N}"; else _SELF="$0"; fi
SCRIPT_DIR="$(cd "$(dirname -- "$_SELF")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

say() { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }

# Ensure env.sh exists (copy from example)
ENV_FILE="$REPO_ROOT/scripts/env.sh"
ENV_EXAMPLE="$REPO_ROOT/scripts/env-example.sh"
if [[ ! -f "$ENV_FILE" ]]; then
  [[ -f "$ENV_EXAMPLE" ]] || { echo "[error] Missing $ENV_EXAMPLE"; exit 1; }
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  say "Created scripts/env.sh from scripts/env-example.sh"
fi

# Load env
# shellcheck disable=SC1090
source "$ENV_FILE"

# Apply JSON overrides (REPO_TO_ANALYZE, REPORTS_DIR, CSV_REPORTS_DIRECTORY)
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/config/apply-scope-env.sh" || true

# Flags (env-driven)
E2E_SKIP_SETUP="${E2E_SKIP_SETUP:-false}"
E2E_SKIP_NEO4J="${E2E_SKIP_NEO4J:-false}"
E2E_SKIP_JQA="${E2E_SKIP_JQA:-false}"
E2E_SKIP_CSV="${E2E_SKIP_CSV:-false}"
E2E_SKIP_NOTEBOOKS="${E2E_SKIP_NOTEBOOKS:-false}"
E2E_STOP_NEO4J="${E2E_STOP_NEO4J:-false}"
E2E_AUTO_INSTALL_JQ="${E2E_AUTO_INSTALL_JQ:-false}"

# Paths
NEO4J_SETUP="$REPO_ROOT/scripts/neo4j/setup-neo4j.sh"
NEO4J_START="$REPO_ROOT/scripts/neo4j/neo4j-start.sh"
NEO4J_SMOKE="$REPO_ROOT/scripts/neo4j/neo4j-smoketest.sh"
NEO4J_STOP="$REPO_ROOT/scripts/neo4j/neo4j-stop.sh"

JQA_SETUP="$REPO_ROOT/scripts/jqa/setup-jqassistant.sh"
JQA_RUN="$REPO_ROOT/scripts/jqa/jqa-run.sh"

CSV_ALL="$REPO_ROOT/scripts/reports/AllCsvReports.sh"

NB_RUN_ALL="$REPO_ROOT/scripts/jupyter/jupyter-run-notebooks.sh"

CSV_OUT_BASE="${CSV_REPORTS_DIRECTORY:-$REPO_ROOT/reports/csv-reports}"
NB_OUT_BASE="${REPORTS_DIR:-$REPO_ROOT/reports}/notebooks"

# -------- Preflight / setup --------
if [[ "$E2E_SKIP_SETUP" != "true" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    if [[ "$E2E_AUTO_INSTALL_JQ" == "true" ]]; then
      if command -v brew >/dev/null 2>&1; then
        say "Installing jq via Homebrew..."
        brew install jq
      else
        echo "[error] jq missing and Homebrew not found. Install jq and re-run."; exit 1
      fi
    else
      echo "[error] jq is required. Install with 'brew install jq' (or set E2E_AUTO_INSTALL_JQ=true)."; exit 1
    fi
  fi
  PY_BIN="${PY_BIN:-python3}"
  command -v "$PY_BIN" >/dev/null 2>&1 || { echo "[error] python3 not found"; exit 1; }
  if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    [[ -d "$REPO_ROOT/.venv" ]] || "$PY_BIN" -m venv "$REPO_ROOT/.venv"
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.venv/bin/activate"
  fi
  [[ -f "$REPO_ROOT/requirements.txt" ]] && pip install -r "$REPO_ROOT/requirements.txt"
  command -v jupyter >/dev/null 2>&1 || { echo "[error] jupyter not found in venv"; exit 1; }
else
  say "Skipping setup (E2E_SKIP_SETUP=true)"
fi

# -------- Neo4j --------
if [[ "$E2E_SKIP_NEO4J" != "true" ]]; then
  [[ -x "$NEO4J_SETUP" ]] && { say "Neo4j setup"; "$NEO4J_SETUP"; }
  say "Neo4j start"; "$NEO4J_START"
  [[ -x "$NEO4J_SMOKE" ]] && { say "Neo4j smoketest"; "$NEO4J_SMOKE"; }
else
  say "Skipping Neo4j (E2E_SKIP_NEO4J=true)"
fi

# -------- jQAssistant --------
if [[ "$E2E_SKIP_JQA" != "true" ]]; then
  [[ -x "$JQA_SETUP" ]] && { say "jQAssistant setup"; "$JQA_SETUP"; }
  say "jQAssistant run"; "$JQA_RUN"
else
  say "Skipping jQAssistant (E2E_SKIP_JQA=true)"
fi

# -------- CSV Reports --------
if [[ "$E2E_SKIP_CSV" != "true" ]]; then
  mkdir -p "$CSV_OUT_BASE"
  say "CSV reports → $CSV_OUT_BASE"
  "$CSV_ALL"
else
  say "Skipping CSV reports (E2E_SKIP_CSV=true)"
fi

# -------- Notebooks --------
if [[ "$E2E_SKIP_NOTEBOOKS" != "true" ]]; then
  mkdir -p "$NB_OUT_BASE"
  say "Notebooks (HTML by default) → $NB_OUT_BASE"
  "$NB_RUN_ALL"
else
  say "Skipping notebooks (E2E_SKIP_NOTEBOOKS=true)"
fi

# -------- Index HTML for notebooks --------
INDEX_HTML="$NB_OUT_BASE/index.html"
mkdir -p "$NB_OUT_BASE"
say "Generating notebooks index: $INDEX_HTML"
{
  echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Notebook Reports</title></head><body>'
  echo '<h1>Notebook Reports</h1><ul>'
  while IFS= read -r -d '' html; do
    rel="${html#$NB_OUT_BASE/}"
    echo "<li><a href=\"./${rel}\">${rel}</a></li>"
  done < <(find "$NB_OUT_BASE" -type f -name "*.html" -print0 | sort -z)
  echo '</ul></body></html>'
} > "$INDEX_HTML"

# -------- Optional stop --------
if [[ "$E2E_STOP_NEO4J" == "true" ]]; then
  say "Stopping Neo4j (E2E_STOP_NEO4J=true)"
  "$REPO_ROOT/scripts/neo4j/neo4j-stop.sh" || true
fi

say "Done."
say "Outputs:"
say "  CSVs:      $CSV_OUT_BASE"
say "  Notebooks: $NB_OUT_BASE"
say "  Index:     $INDEX_HTML"

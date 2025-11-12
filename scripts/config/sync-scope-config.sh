#!/usr/bin/env bash
# Syncs config/analysis-scope.json into neo4j/import/ so APOC can read it.
# Safe no-op if the JSON file does not exist.

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

SRC="$REPO_ROOT/config/analysis-scope.json"
DEST_DIR="$REPO_ROOT/neo4j/import"
DEST="$DEST_DIR/analysis-scope.json"

log() { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }

if [[ ! -f "$SRC" ]]; then
  log "analysis-scope.json not found; skipping sync (expected at $SRC)"
  exit 0
fi

mkdir -p "$DEST_DIR"
cp -f "$SRC" "$DEST"

# Optional: validate JSON when jq is available
if command -v jq >/dev/null 2>&1; then
  jq . "$DEST" >/dev/null
fi

log "Synced scope JSON -> $DEST"

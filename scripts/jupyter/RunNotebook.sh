#!/usr/bin/env bash
# RunNotebook.sh — Run all notebooks by folder and produce separate outputs per notebook.
#
# Folders scanned (non-recursive):
#   - jupyter/custom
#   - jupyter/overview (if the folder exists)
#
# For each notebook <Name>.ipynb, outputs are written to:
#   reports/notebooks/<Name>/
#     - <Name>.ipynb   (executed)
#     - <Name>.html    (interactive Plotly)
#     - <Name>.md      (static)
#
# Requirements:
#   - scripts/jupyter/executeJupyterNotebook.sh
#   - jupyter + nbconvert installed
#
# Notes:
#   - This script avoids Bash 4+ features (e.g., mapfile) for macOS compatibility (Bash 3.2).
#   - Assumes notebook filenames do not contain spaces.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXEC_ONE="$SCRIPT_DIR/executeJupyterNotebook.sh"

if [[ ! -x "$EXEC_ONE" ]]; then
  echo "[error] Helper not found or not executable: $EXEC_ONE"
  echo "        Ensure scripts/jupyter/executeJupyterNotebook.sh exists and is executable (chmod +x)."
  exit 1
fi

# Notebook folders to scan (simple and predictable)
NB_DIRS=(
  "$ROOT_DIR/jupyter/custom"
  "$ROOT_DIR/jupyter/overview"
)

OUT_BASE="$ROOT_DIR/reports/notebooks"
mkdir -p "$OUT_BASE"

run_one() {
  # Runs a single notebook and stores outputs in a dedicated directory.
  local nb_path="$1"
  local nb_name
  nb_name="$(basename -- "$nb_path")"
  local stem="${nb_name%.*}"

  local out_dir="$OUT_BASE/$stem"
  mkdir -p "$out_dir"

  echo "[run] $nb_name -> $out_dir"
  # Call the single-notebook helper with explicit OUT_DIR
  if "$EXEC_ONE" "$nb_path" "$out_dir"; then
    echo "[ok]  $nb_name"
  else
    echo "[warn] Failed to execute $nb_name (continuing)"
  fi
}

found_any="false"

# Iterate folders; use POSIX-friendly find+sort; avoid mapfile/readarray.
for dir in "${NB_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    continue
  fi

  # Collect notebooks (non-recursive)
  notebooks="$(find "$dir" -maxdepth 1 -type f -name "*.ipynb" | sort)"
  if [[ -z "$notebooks" ]]; then
    echo "[info] No notebooks found in: $dir"
    continue
  fi

  found_any="true"

  # Loop over lines; filenames without spaces are assumed
  for nb in $notebooks; do
    run_one "$nb"
  done
done

if [[ "$found_any" != "true" ]]; then
  echo "[warn] No notebooks found in jupyter/custom nor jupyter/overview."
fi

echo "[done] RunNotebook.sh finished."

#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/jupyter/jupyter-run-notebooks.sh

# Resolve script dir (bash/zsh)
if [[ -n "${BASH_SOURCE:-}" ]]; then _SELF="${BASH_SOURCE[0]}"; elif [[ -n "${ZSH_VERSION:-}" ]]; then _SELF="${(%):-%N}"; else _SELF="$0"; fi
SCRIPT_DIR="$(cd "$(dirname -- "$_SELF")" && pwd -P)"
REPO_ROOT="${ROOT_DIRECTORY:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
EXEC_ONE="${SCRIPT_DIR}/jupyter-exec-notebook.sh"

[[ -x "$EXEC_ONE" ]] || { echo "[error] Missing or non-executable: $EXEC_ONE"; exit 1; }

NB_DIRS=(
  "${REPO_ROOT}/jupyter"
)

OUT_BASE="${REPORTS_DIRECTORY:-${REPO_ROOT}/reports}/notebooks"
mkdir -p "$OUT_BASE"

run_one() {
  local nb_path="$1"
  local nb_file nb_stem out_dir
  nb_file="$(basename -- "$nb_path")"
  nb_stem="${nb_file%.*}"
  out_dir="${OUT_BASE}/${nb_stem}"
  mkdir -p "$out_dir"
  echo "[run] $nb_file -> $out_dir"
  if "$EXEC_ONE" "$nb_path" "$out_dir"; then
    echo "[ok]  $nb_file"
  else
    echo "[warn] Failed: $nb_file"
  fi
}

found_any="false"

for dir in "${NB_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  notebooks="$(find "$dir" -maxdepth 1 -type f -name "*.ipynb" | sort)"
  [[ -n "$notebooks" ]] || { echo "[info] No notebooks in: $dir"; continue; }
  found_any="true"
  for nb in $notebooks; do
    run_one "$nb"
  done
done

if [[ "$found_any" != "true" ]]; then
  echo "[warn] No notebooks found."
fi

echo "[done] jupyter-run-notebooks.sh finished."

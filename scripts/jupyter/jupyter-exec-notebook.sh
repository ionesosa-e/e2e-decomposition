#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/jupyter/jupyter-exec-notebook.sh <notebook.ipynb> [<output_dir>]

# Resolve script dir (bash/zsh)
if [[ -n "${BASH_SOURCE:-}" ]]; then _SELF="${BASH_SOURCE[0]}"; elif [[ -n "${ZSH_VERSION:-}" ]]; then _SELF="${(%):-%N}"; else _SELF="$0"; fi
SCRIPT_DIR="$(cd "$(dirname -- "$_SELF")" && pwd -P)"
REPO_ROOT="${ROOT_DIRECTORY:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"

NOTEBOOK_PATH="${1:-}"
[[ -n "$NOTEBOOK_PATH" ]] || { echo "Usage: $0 <notebook.ipynb> [output_dir]"; exit 1; }
[[ -f "$NOTEBOOK_PATH" ]] || { echo "File not found: $NOTEBOOK_PATH"; exit 1; }

NB_DIR="$(cd "$(dirname -- "$NOTEBOOK_PATH")" && pwd -P)"
NB_FILE="$(basename -- "$NOTEBOOK_PATH")"
NB_NAME="${NB_FILE%.*}"
ABS_NOTEBOOK="${NB_DIR}/${NB_FILE}"

OUT_ARG="${2:-}"
OUT_BASE="${REPORTS_DIRECTORY:-${REPO_ROOT}/reports}/notebooks"
OUT_DIR="${OUT_ARG:-${OUT_BASE}/${NB_NAME}}"
mkdir -p "${OUT_DIR}"

POSTFIX="${JUPYTER_OUTPUT_FILE_POSTFIX:-}"
OUT_NAME="${NB_NAME}${POSTFIX}"
OUT_IPYNB="${OUT_DIR}/${OUT_NAME}.ipynb"
OUT_HTML="${OUT_DIR}/${OUT_NAME}.html"
OUT_MD="${OUT_DIR}/${OUT_NAME}.md"

command -v jupyter >/dev/null 2>&1 || { echo "'jupyter' not found in PATH"; exit 1; }
export PLOTLY_RENDERER="${PLOTLY_RENDERER:-notebook_connected}"

# Optional .env for notebooks
if [[ -n "${NEO4J_INITIAL_PASSWORD:-}" && ! -f "${NB_DIR}/.env" ]]; then
  printf "NEO4J_INITIAL_PASSWORD=%s\n" "${NEO4J_INITIAL_PASSWORD}" > "${NB_DIR}/.env"
fi

ENABLE_NOTEBOOK_IPYNB="${ENABLE_NOTEBOOK_IPYNB:-false}"
ENABLE_NOTEBOOK_MD="${ENABLE_NOTEBOOK_MD:-false}"

if [[ "${ENABLE_NOTEBOOK_IPYNB}" == "true" ]]; then
  # Execute once to .ipynb, then convert to HTML/MD
  jupyter nbconvert --to notebook --execute "${ABS_NOTEBOOK}" \
    --output "${OUT_NAME}" --output-dir "${OUT_DIR}" \
    --ExecutePreprocessor.timeout=1800

  jupyter nbconvert --to html --no-input --template lab \
    "${OUT_IPYNB}" --output "${OUT_NAME}" --output-dir "${OUT_DIR}"

  if [[ "${ENABLE_NOTEBOOK_MD}" == "true" ]]; then
    jupyter nbconvert --to markdown --no-input \
      "${OUT_IPYNB}" --output "${OUT_NAME}" --output-dir "${OUT_DIR}"
    sed -E '/<style( scoped)?>/,/<\/style>/d' "${OUT_MD}" > "${OUT_MD}.nostyle" && mv -f "${OUT_MD}.nostyle" "${OUT_MD}"
  fi
else
  # Default: only HTML (executed)
  jupyter nbconvert --to html --execute --no-input --template lab \
    "${ABS_NOTEBOOK}" --output "${OUT_NAME}" --output-dir "${OUT_DIR}" \
    --ExecutePreprocessor.timeout=1800

  if [[ "${ENABLE_NOTEBOOK_MD}" == "true" ]]; then
    jupyter nbconvert --to markdown --execute --no-input \
      "${ABS_NOTEBOOK}" --output "${OUT_NAME}" --output-dir "${OUT_DIR}" \
      --ExecutePreprocessor.timeout=1800
    sed -E '/<style( scoped)?>/,/<\/style>/d' "${OUT_MD}" > "${OUT_MD}.nostyle" && mv -f "${OUT_MD}.nostyle" "${OUT_MD}"
  fi
fi

echo "outputs:"
[[ -f "${OUT_IPYNB}" ]] && echo "  ${OUT_IPYNB}"
echo "  ${OUT_HTML}"
[[ -f "${OUT_MD}"    ]] && echo "  ${OUT_MD}"

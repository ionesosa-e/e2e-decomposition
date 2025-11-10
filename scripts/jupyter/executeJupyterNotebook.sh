#!/usr/bin/env bash
# Executes a single Jupyter Notebook and generates executed .ipynb, .html, and .md.
# Optional: PDF via ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION.
#
# Usage:
#   scripts/jupyter/executeJupyterNotebook.sh <path/to/notebook.ipynb> [<output_dir>]
#
# Environment variables (optional):
#   JUPYTER_OUTPUT_FILE_POSTFIX               e.g. "" | ".nbconvert" | ".output"
#   ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION    any non-empty value enables PDF export
#   PLOTLY_RENDERER                           defaults to "notebook_connected" if not set

set -o errexit -o pipefail

NOTEBOOK_PATH="${1:-}"
OUT_DIR="${2:-./}"  # default to current working directory if not provided

if [[ -z "$NOTEBOOK_PATH" ]]; then
  echo "executeJupyterNotebook: Usage: $0 <jupyter notebook file> [<output_dir>]" >&2
  exit 1
fi
if [[ ! -f "$NOTEBOOK_PATH" ]]; then
  echo "executeJupyterNotebook: File not found: $NOTEBOOK_PATH" >&2
  exit 1
fi

# Normalize paths (absolute)
NB_DIR="$(cd "$(dirname -- "$NOTEBOOK_PATH")" && pwd)"
NB_BASENAME="$(basename -- "$NOTEBOOK_PATH")"
ABS_NOTEBOOK="${NB_DIR}/${NB_BASENAME}"

OUT_DIR="$(mkdir -p "$OUT_DIR" && cd "$OUT_DIR" && pwd)"

# Postfix & optional PDF flag
JUPYTER_OUTPUT_FILE_POSTFIX="${JUPYTER_OUTPUT_FILE_POSTFIX:-}"
ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION="${ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION:-}"
if [[ "$ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION" == "false" ]]; then
  ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION=""
fi

# Split name
NB_EXT="${NB_BASENAME##*.}"
NB_NAME="${NB_BASENAME%.*}"

OUT_NAME="${NB_NAME}${JUPYTER_OUTPUT_FILE_POSTFIX}"
OUT_IPYNB="${OUT_DIR}/${OUT_NAME}.${NB_EXT}"
OUT_HTML="${OUT_DIR}/${OUT_NAME}.html"
OUT_MD="${OUT_DIR}/${OUT_NAME}.md"

echo "executeJupyterNotebook: NOTEBOOK_PATH=${ABS_NOTEBOOK}"
echo "executeJupyterNotebook: OUT_DIR=${OUT_DIR}"
echo "executeJupyterNotebook: OUT_IPYNB=${OUT_IPYNB}"
echo "executeJupyterNotebook: OUT_HTML=${OUT_HTML}"
echo "executeJupyterNotebook: OUT_MD=${OUT_MD}"

# Dependencies
if ! command -v jupyter >/dev/null 2>&1; then
  echo "executeJupyterNotebook: 'jupyter' not found in PATH. Please install from requirements.txt." >&2
  exit 1
fi

# Ensure Plotly interactive renderer for headless HTML exports
export PLOTLY_RENDERER="${PLOTLY_RENDERER:-notebook_connected}"

# Optional: propagate NEO4J_INITIAL_PASSWORD next to the original notebook (harmless if unused)
if [[ -n "${NEO4J_INITIAL_PASSWORD:-}" ]]; then
  if [[ ! -f "${NB_DIR}/.env" ]]; then
    echo "executeJupyterNotebook: Writing ${NB_DIR}/.env with NEO4J_INITIAL_PASSWORD..."
    echo "NEO4J_INITIAL_PASSWORD=${NEO4J_INITIAL_PASSWORD}" > "${NB_DIR}/.env"
  fi
fi

# Execute to .ipynb (headless) WITHOUT changing cwd; write results into OUT_DIR
echo "executeJupyterNotebook: Executing notebook with nbconvert..."
jupyter nbconvert \
  --to notebook \
  --execute "${ABS_NOTEBOOK}" \
  --output "${OUT_NAME}" \
  --output-dir "${OUT_DIR}" \
  --ExecutePreprocessor.timeout=1800

echo "executeJupyterNotebook: Executed -> ${OUT_IPYNB}"

# Convert to HTML (keeps Plotly interactivity). Template 'lab' helps with JS assets.
echo "executeJupyterNotebook: Converting to HTML..."
jupyter nbconvert \
  --to html \
  --no-input \
  --template lab \
  "${OUT_IPYNB}" \
  --output "${OUT_NAME}" \
  --output-dir "${OUT_DIR}"

# Convert to Markdown (no input cells) and strip <style> blocks (mac-compatible)
echo "executeJupyterNotebook: Converting to Markdown..."
jupyter nbconvert \
  --to markdown \
  --no-input \
  "${OUT_IPYNB}" \
  --output "${OUT_NAME}" \
  --output-dir "${OUT_DIR}"

# Remove <style>…</style> for cleaner diffs
sed -E '/<style( scoped)?>/,/<\\/style>/d' "${OUT_MD}" > "${OUT_MD}.nostyle" && mv -f "${OUT_MD}.nostyle" "${OUT_MD}"

# Optional PDF
if [[ -n "$ENABLE_JUPYTER_NOTEBOOK_PDF_GENERATION" ]]; then
  echo "executeJupyterNotebook: Converting to PDF (webpdf)..."
  jupyter nbconvert \
    --to webpdf \
    --no-input \
    --allow-chromium-download \
    --disable-chromium-sandbox \
    "${OUT_IPYNB}" \
    --output "${OUT_NAME}" \
    --output-dir "${OUT_DIR}"
fi

echo "executeJupyterNotebook: Done."

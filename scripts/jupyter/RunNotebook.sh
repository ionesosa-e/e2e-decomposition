#!/usr/bin/env bash
# Executes a single Jupyter Notebook using the current Python environment (e.g., venv).
# Writes executed .ipynb and a Markdown export into the current working directory.

set -o errexit -o pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <notebook path (.ipynb)>" >&2
  exit 1
fi

NOTEBOOK="$1"
if [ ! -f "${NOTEBOOK}" ]; then
  echo "RunNotebook: File not found: ${NOTEBOOK}" >&2
  exit 1
fi

# Sanity check that Jupyter is available in the active environment
jupyter --version >/dev/null

nb_dir="$(dirname "${NOTEBOOK}")"
nb_base="$(basename -- "${NOTEBOOK}")"
nb_name="${nb_base%.*}"

echo "RunNotebook: Executing ${nb_base} ..."
mkdir -p "${nb_dir}/${nb_name}_files"

# Execute notebook in-place to a new output file name: <name>.output.ipynb
jupyter nbconvert --to notebook \
  --execute "${NOTEBOOK}" \
  --output "${nb_name}.output" \
  --output-dir "${nb_dir}" \
  --ExecutePreprocessor.timeout=480

echo "RunNotebook: Exporting Markdown ..."
jupyter nbconvert --to markdown --no-input "${nb_dir}/${nb_name}.output.ipynb"

echo "RunNotebook: Done."

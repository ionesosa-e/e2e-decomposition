#!/usr/bin/env bash
# Executes all .ipynb files in the jupyter/ folder using the current Python environment (e.g., venv).
# Produces executed .ipynb and Markdown files next to each notebook.

set -o errexit -o pipefail

# Resolve repo paths
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
SCRIPTS_DIR="$( cd "${THIS_DIR}/../.." && pwd -P )"
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"
JUPYTER_DIR="${REPO_ROOT}/jupyter"

echo "JupyterReports: JUPYTER_DIR=${JUPYTER_DIR}"

if [ ! -d "${JUPYTER_DIR}" ]; then
  echo "JupyterReports: Missing jupyter/ directory. Create notebooks first." >&2
  exit 1
fi

# Ensure jupyter is installed in the active environment
jupyter --version >/dev/null

# Run each notebook
for nb in "${JUPYTER_DIR}"/*.ipynb; do
  [ -e "$nb" ] || { echo "JupyterReports: No notebooks found."; exit 0; }
  echo "JupyterReports: Running $(basename "$nb") ..."
  "${SCRIPTS_DIR}/jupyter/RunNotebook.sh" "$nb"
done

echo "JupyterReports: All notebooks executed."

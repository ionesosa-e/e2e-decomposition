#!/usr/bin/env bash
# Runs all CSV report blocks (Overview, ArtifactDependencies, Java, Metrics).
# Each block script writes its own output under reports/<block>-csv.

set -o errexit -o pipefail

# Resolve repo paths
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
REPORTS_DIR="$( cd "${THIS_DIR}/.." && pwd -P )"          # scripts/reports
SCRIPTS_DIR="$( cd "${REPORTS_DIR}/.." && pwd -P )"       # scripts
REPO_ROOT="$( cd "${SCRIPTS_DIR}/.." && pwd -P )"         # repo root

echo "CsvReports: repo=${REPO_ROOT}"
echo "CsvReports: scripts=${SCRIPTS_DIR}"

# List of block scripts to run (order matters)
BLOCK_SCRIPTS=(
  "${REPORTS_DIR}/OverviewCsv.sh"
  "${REPORTS_DIR}/ArtifactDependenciesCsv.sh"
  "${REPORTS_DIR}/JavaCsv.sh"
  "${REPORTS_DIR}/MetricsCsv.sh"
)

# Env toggle: set to any non-empty value to stop on first block error
# Example: STOP_ON_ERROR=true scripts/reports/compilations/CsvReports.sh
STOP_ON_ERROR="${STOP_ON_ERROR:-""}"

failures=()

run_block() {
  local script_path="$1"
  local name
  name="$(basename "${script_path}")"

  if [[ ! -x "${script_path}" ]]; then
    if [[ -f "${script_path}" ]]; then
      echo "CsvReports: ⚠️  ${name} exists but is not executable. Skipping."
    else
      echo "CsvReports: ℹ️  ${name} not found. Skipping."
    fi
    return 0
  fi

  echo "CsvReports: ▶️  Running ${name} ..."
  if ! "${script_path}"; then
    echo "CsvReports: ❌ ${name} failed."
    failures+=("${name}")
    if [[ -n "${STOP_ON_ERROR}" ]]; then
      exit 1
    fi
  else
    echo "CsvReports: ✅ ${name} done."
  fi
}

start_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "CsvReports: Started at ${start_ts}"
echo

for block in "${BLOCK_SCRIPTS[@]}"; do
  run_block "${block}"
  echo
done

end_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "CsvReports: Finished at ${end_ts}"

if (( ${#failures[@]} > 0 )); then
  echo "CsvReports: Completed with failures in:"
  for f in "${failures[@]}"; do echo "  - ${f}"; done
  exit 1
else
  echo "CsvReports: All blocks completed successfully."
fi

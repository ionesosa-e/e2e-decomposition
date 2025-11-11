#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
CATEGORIES_DIR="${THIS_DIR}/categories"

echo "AllCsvReports: scripts=${THIS_DIR}"

BLOCKS=(
  "${CATEGORIES_DIR}/APIEntryPointsCsv.sh"
  "${CATEGORIES_DIR}/ConfigurationEnvironmentCsv.sh"
  "${CATEGORIES_DIR}/DatabaseCsv.sh"
  "${CATEGORIES_DIR}/DependenciesCsv.sh"
  "${CATEGORIES_DIR}/ExternalIntegrationCsv.sh"
  "${CATEGORIES_DIR}/FanInFanOutCsv.sh"
  "${CATEGORIES_DIR}/HighLevelArchitectureCsv.sh"
  "${CATEGORIES_DIR}/SecurityCsv.sh"
  "${CATEGORIES_DIR}/TechnologyStackCsv.sh"
  "${CATEGORIES_DIR}/TestingCsv.sh"
)

start_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "AllCsvReports: Started at ${start_ts}"
echo

for script in "${BLOCKS[@]}"; do
  name="$(basename "${script}")"
  if [[ -x "${script}" ]]; then
    echo ">> ${name}"
    "${script}"
    echo "<< ${name} done"
  else
    if [[ -f "${script}" ]]; then
      echo "WARN: ${name} exists but is not executable, skipping."
    else
      echo "INFO: ${name} not found, skipping."
    fi
  fi
  echo
done

end_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "AllCsvReports: Finished at ${end_ts}"

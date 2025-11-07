#!/usr/bin/env bash
# Runs all Custom_Queries block scripts (one per subfolder) and writes CSVs under reports/custom-queries-csv/*

set -o errexit -o pipefail

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
CUSTOM_DIR="${THIS_DIR}/custom"

echo "CustomQueriesCsv: scripts=${THIS_DIR}"

BLOCKS=(
  "${CUSTOM_DIR}/APIEntryPointsCsv.sh"
  "${CUSTOM_DIR}/ConfigurationEnvironmentCsv.sh"
  "${CUSTOM_DIR}/DatabaseCsv.sh"
  "${CUSTOM_DIR}/DependenciesCsv.sh"
  "${CUSTOM_DIR}/ExternalIntegrationCsv.sh"
  "${CUSTOM_DIR}/FanInFanOutCsv.sh"
  "${CUSTOM_DIR}/HighLevelArchitectureCsv.sh"
  "${CUSTOM_DIR}/SecurityCsv.sh"
  "${CUSTOM_DIR}/TechnologyStackCsv.sh"
  "${CUSTOM_DIR}/TestingCsv.sh"
)

start_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "CustomQueriesCsv: Started at ${start_ts}"
echo

for script in "${BLOCKS[@]}"; do
  name="$(basename "${script}")"
  if [[ -x "${script}" ]]; then
    echo "▶️  ${name}"
    "${script}"
    echo "✅ ${name}"
  else
    if [[ -f "${script}" ]]; then
      echo "⚠️  ${name} exists but is not executable, skipping."
    else
      echo "ℹ️  ${name} not found, skipping."
    fi
  fi
  echo
done

end_ts="$(date +'%Y-%m-%dT%H:%M:%S%z')"
echo "CustomQueriesCsv: Finished at ${end_ts}"

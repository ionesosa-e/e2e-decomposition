#!/usr/bin/env bash
set -euo pipefail

# Requires: source scripts/env.sh

ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
JQA_VER="${JQASSISTANT_CLI_VERSION:?missing JQASSISTANT_CLI_VERSION}"
JQA_ARTIFACT="${JQASSISTANT_CLI_ARTIFACT:-jqassistant-commandline-neo4jv5}"
JQA_HOME="${TOOLS_DIR}/${JQA_ARTIFACT}-${JQA_VER}"

WORK_DIR="${ROOT_DIR}/jqassistant"
CONF_MAIN="${WORK_DIR}/.jqassistant.yml"
CONF_REMOTE="${WORK_DIR}/.jqassistant.remote.yml"
TARGET="${1:-${REPO_TO_ANALYZE:?missing REPO_TO_ANALYZE}}"

[[ -x "${JQA_HOME}/bin/jqassistant" ]] || { echo "jQAssistant CLI not installed. Run scripts/setupJQAssistant.sh"; exit 1; }
[[ -d "${WORK_DIR}" ]] || { echo "Missing jqassistant directory: ${WORK_DIR}"; exit 1; }

# Ensure a .jqassistant.yml is visible to the CLI from the working dir.
CLEANUP_LINK=""
if [[ ! -f "${CONF_MAIN}" ]]; then
  if [[ -f "${CONF_REMOTE}" ]]; then
    ln -s ".jqassistant.remote.yml" "${CONF_MAIN}"
    CLEANUP_LINK="${CONF_MAIN}"
  else
    echo "Config not found. Provide ${CONF_MAIN} or ${CONF_REMOTE}."
    exit 1
  fi
fi

echo "Working dir: ${WORK_DIR}"
echo "Using config: ${CONF_MAIN}"
echo "Scanning: ${TARGET}"

pushd "${WORK_DIR}" >/dev/null

# Scan artifacts (absolute or relative path works)
"${JQA_HOME}/bin/jqassistant" scan -f "${TARGET}"

# Analyze according to rules in the config
"${JQA_HOME}/bin/jqassistant" analyze

popd >/dev/null

# Remove temporary symlink if we created one
if [[ -n "${CLEANUP_LINK}" ]]; then
  rm -f "${CLEANUP_LINK}"
fi

echo "Reports at: ${ROOT_DIR}/runtime/jqassistant/report"

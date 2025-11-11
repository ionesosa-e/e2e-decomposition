#!/usr/bin/env bash
set -euo pipefail

# Requires: source scripts/env.sh

ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
JQA_VER="${JQASSISTANT_CLI_VERSION:?missing JQASSISTANT_CLI_VERSION}"
JQA_ARTIFACT="${JQASSISTANT_CLI_ARTIFACT:-jqassistant-commandline-neo4jv5}"
JQA_HOME="${JQA_HOME:-${TOOLS_DIR}/${JQA_ARTIFACT}-${JQA_VER}}"

WORK_DIR="${ROOT_DIR}/jqassistant"
CONF_MAIN="${WORK_DIR}/.jqassistant.yml"
TARGET="${1:-${REPO_TO_ANALYZE:?missing REPO_TO_ANALYZE}}"

[[ -x "${JQA_HOME}/bin/jqassistant" ]] || { echo "jQAssistant CLI not installed. Run scripts/setupJQAssistant.sh"; exit 1; }
[[ -d "${WORK_DIR}" ]] || { echo "Missing jqassistant directory: ${WORK_DIR}"; exit 1; }
[[ -f "${CONF_MAIN}" ]] || { echo "Config not found: ${CONF_MAIN}"; exit 1; }

echo "Working dir: ${WORK_DIR}"
echo "Using config: ${CONF_MAIN}"
echo "Scanning: ${TARGET}"

pushd "${WORK_DIR}" >/dev/null

# Scan target (jar files, dirs, etc.)
"${JQA_HOME}/bin/jqassistant" scan -f "${TARGET}"

# Analyze according to rules in the config
"${JQA_HOME}/bin/jqassistant" analyze

popd >/dev/null

echo "Reports at: ${ROOT_DIR}/runtime/jqassistant/report"

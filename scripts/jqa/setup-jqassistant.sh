#!/usr/bin/env bash
set -euo pipefail

# Requires: source scripts/env.sh

JQA_VER="${JQASSISTANT_CLI_VERSION:?missing JQASSISTANT_CLI_VERSION}"
JQA_ARTIFACT="${JQASSISTANT_CLI_ARTIFACT:-jqassistant-commandline-neo4jv5}"
JQA_URL_BASE="${JQASSISTANT_CLI_DOWNLOAD_URL:?missing JQASSISTANT_CLI_DOWNLOAD_URL}"
ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
DL_DIR="${DOWNLOADS_DIRECTORY:?missing DOWNLOADS_DIRECTORY}"

JQA_NAME="${JQA_ARTIFACT}-${JQA_VER}"
JQA_ZIP="${JQA_NAME}-distribution.zip"
JQA_URL="${JQA_URL_BASE}/${JQA_ARTIFACT}/${JQA_VER}/${JQA_ZIP}"
JQA_HOME="${JQA_HOME:-${TOOLS_DIR}/${JQA_NAME}}"

mkdir -p "${TOOLS_DIR}" "${DL_DIR}"

if [[ ! -d "${JQA_HOME}" ]]; then
  curl -L --fail -o "${DL_DIR}/${JQA_ZIP}" "${JQA_URL}"
  unzip -q "${DL_DIR}/${JQA_ZIP}" -d "${TOOLS_DIR}"
fi

echo "jQAssistant installed at: ${JQA_HOME}"
echo "Binary: ${JQA_HOME}/bin/jqassistant"

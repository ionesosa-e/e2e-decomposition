#!/usr/bin/env bash
set -euo pipefail
# Requires: source scripts/env.sh

# --- Required env ---
ROOT_DIR="${ROOT_DIRECTORY:?missing ROOT_DIRECTORY}"
TOOLS_DIR="${TOOLS_DIRECTORY:?missing TOOLS_DIRECTORY}"
DL_DIR="${DOWNLOADS_DIRECTORY:?missing DOWNLOADS_DIRECTORY}"

NEO4J_ED="${NEO4J_EDITION:?missing NEO4J_EDITION}"
NEO4J_VER="${NEO4J_VERSION:?missing NEO4J_VERSION}"
NEO4J_HTTP="${NEO4J_HTTP_PORT:?missing NEO4J_HTTP_PORT}"
NEO4J_HTTPS="${NEO4J_HTTPS_PORT:?missing NEO4J_HTTPS_PORT}"
NEO4J_BOLT="${NEO4J_BOLT_PORT:?missing NEO4J_BOLT_PORT}"

APOC_VER="${APOC_VERSION:?missing APOC_VERSION}"
GDS_ED="${GDS_EDITION:?missing GDS_EDITION}"      # open | full
GDS_OPEN_VER="${GDS_VERSION_OPEN:?missing GDS_VERSION_OPEN}"
GDS_FULL_VER="${GDS_VERSION_FULL:?missing GDS_VERSION_FULL}"

NEO4J_DATA_DIR="${NEO4J_DATA_DIRECTORY:?missing NEO4J_DATA_DIRECTORY}"
NEO4J_RUN_DIR="${NEO4J_RUNTIME_DIRECTORY:?missing NEO4J_RUNTIME_DIRECTORY}"
NEO4J_IMPORT_DIR="${NEO4J_IMPORT_DIRECTORY:?missing NEO4J_IMPORT_DIRECTORY}"

NEO4J_USER_NAME="${NEO4J_USER:-neo4j}"
NEO4J_PWD="${NEO4J_INITIAL_PASSWORD:?missing NEO4J_INITIAL_PASSWORD}"

# --- Derived paths (honrar NEO4J_HOME si viene de env) ---
NEO4J_NAME="neo4j-${NEO4J_ED}-${NEO4J_VER}"
NEO4J_ARCHIVE="${NEO4J_NAME}-unix.tar.gz"
NEO4J_URL="https://dist.neo4j.org/${NEO4J_ARCHIVE}"
NEO4J_HOME="${NEO4J_HOME:-${TOOLS_DIR}/${NEO4J_NAME}}"
NEO4J_CONF_FILE="${NEO4J_HOME}/conf/neo4j.conf"
NEO4J_PLUGINS_DIR="${NEO4J_HOME}/plugins"
APOC_JAR="apoc-${APOC_VER}-core.jar"
NEO4J_MAJOR="${NEO4J_VER%%.*}"
CSHELL="${NEO4J_HOME}/bin/cypher-shell"
NADM="${NEO4J_HOME}/bin/neo4j-admin"

# --- Folders ---
mkdir -p "${TOOLS_DIR}" "${DL_DIR}" "${NEO4J_DATA_DIR}" "${NEO4J_RUN_DIR}" \
         "${NEO4J_IMPORT_DIR}" "${NEO4J_RUN_DIR}/logs" "${NEO4J_RUN_DIR}/run"

# --- Helpers ---
is_darwin() { [[ "$(uname)" == "Darwin" ]]; }
del_key() {
  local key="$1" file="$2"
  if is_darwin; then sed -i '' "/^${key}=.*/d" "${file}"; else sed -i "/^${key}=.*/d" "${file}"; fi
}
ensure_cfg() {
  local key="$1" val="$2"
  del_key "${key}" "${NEO4J_CONF_FILE}"
  echo "${key}=${val}" >> "${NEO4J_CONF_FILE}"
}
ensure_line_in_file() {
  local line="$1" file="$2"
  if ! grep -qF -- "${line}" "${file}" 2>/dev/null; then echo "${line}" >> "${file}"; fi
}

# --- Download and unpack Neo4j (idempotente) ---
if [[ ! -d "${NEO4J_HOME}" ]]; then
  echo "[setupNeo4j] Downloading ${NEO4J_ARCHIVE} ..."
  curl -L --fail -o "${DL_DIR}/${NEO4J_ARCHIVE}" "${NEO4J_URL}"
  tar -xf "${DL_DIR}/${NEO4J_ARCHIVE}" -C "${TOOLS_DIR}"
fi

# --- Ensure config files exist ---
mkdir -p "$(dirname "${NEO4J_CONF_FILE}")" "${NEO4J_PLUGINS_DIR}"
touch "${NEO4J_CONF_FILE}"
touch "${NEO4J_HOME}/conf/apoc.conf"

# --- Idempotent marker ---
if ! grep -q "^# E2E-decomposition configuration (idempotent)" "${NEO4J_CONF_FILE}" 2>/dev/null; then
  {
    echo ""
    echo "# E2E-decomposition configuration (idempotent)"
  } >> "${NEO4J_CONF_FILE}"
fi

# --- Core config ---
ensure_cfg "server.directories.data" "${NEO4J_DATA_DIR}"
ensure_cfg "server.directories.logs" "${NEO4J_RUN_DIR}/logs"
ensure_cfg "server.directories.dumps.root" "${NEO4J_RUN_DIR}/dumps"
ensure_cfg "server.directories.run" "${NEO4J_RUN_DIR}/run"
ensure_cfg "server.directories.transaction.logs.root" "${NEO4J_DATA_DIR}/transactions"
ensure_cfg "server.directories.import" "${NEO4J_IMPORT_DIR}"
ensure_cfg "server.bolt.listen_address" ":${NEO4J_BOLT}"
ensure_cfg "server.http.listen_address" ":${NEO4J_HTTP}"
ensure_cfg "server.https.listen_address" ":${NEO4J_HTTPS}"
ensure_cfg "dbms.security.procedures.unrestricted" "apoc.*,gds.*"
ensure_cfg "dbms.security.procedures.allowlist" "apoc.*,gds.*"
ensure_cfg "server.memory.heap.initial_size" "4g"
ensure_cfg "server.memory.heap.max_size" "6g"
ensure_cfg "server.memory.pagecache.size" "4g"
ensure_cfg "dbms.memory.transaction.total.max" "3g"

# --- Initial password (Neo4j 5+/2025.x) ---
if [[ ! -f "${NEO4J_DATA_DIR}/dbms/auth.ini" ]]; then
  echo "[setupNeo4j] Setting initial password ..."
  "${NADM}" dbms set-initial-password "${NEO4J_PWD}"
fi

# --- Install APOC core jar (idempotent) ---
if [[ ! -f "${NEO4J_PLUGINS_DIR}/${APOC_JAR}" ]]; then
  echo "[setupNeo4j] Installing APOC ${APOC_VER} ..."
  curl -L --fail -o "${DL_DIR}/${APOC_JAR}" "https://github.com/neo4j/apoc/releases/download/${APOC_VER}/${APOC_JAR}"
  rm -f "${NEO4J_PLUGINS_DIR}/apoc"*.jar || true
  cp "${DL_DIR}/${APOC_JAR}" "${NEO4J_PLUGINS_DIR}/"
fi
ensure_line_in_file "apoc.export.file.enabled=true" "${NEO4J_HOME}/conf/apoc.conf"

# --- Install GDS (open o full) idempotente ---
if [[ "${GDS_ED}" == "open" ]]; then
  GDS_JAR="open-graph-data-science-${GDS_OPEN_VER}-for-neo4j-${NEO4J_MAJOR}.jar"
  GDS_URL="https://github.com/JohT/open-graph-data-science-packaging/releases/download/v${GDS_OPEN_VER}/${GDS_JAR}"
else
  GDS_JAR="neo4j-graph-data-science-${GDS_FULL_VER}.jar"
  GDS_URL="https://github.com/neo4j/graph-data-science/releases/download/${GDS_FULL_VER}/${GDS_JAR}"
fi

if [[ ! -f "${NEO4J_PLUGINS_DIR}/${GDS_JAR}" ]]; then
  echo "[setupNeo4j] Installing GDS (${GDS_ED}) ..."
  curl -L --fail -o "${DL_DIR}/${GDS_JAR}" "${GDS_URL}"
  rm -f "${NEO4J_PLUGINS_DIR}/"*[gG]raph-data-science*".jar" || true
  cp "${DL_DIR}/${GDS_JAR}" "${NEO4J_PLUGINS_DIR}/"
fi

# --- PATH (opcional para siguientes scripts) ---
export PATH="${NEO4J_HOME}/bin:${PATH}"

echo "Neo4j installed at: ${NEO4J_HOME}"
echo "Plugins:"
ls -1 "${NEO4J_PLUGINS_DIR}" || true
echo "HTTP: http://localhost:${NEO4J_HTTP}  BOLT: bolt://localhost:${NEO4J_BOLT}"

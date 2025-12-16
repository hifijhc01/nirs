#!/usr/bin/env bash
set -euo pipefail

echo "=== [extensions] install.sh start (build-time) ==="

JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
INJECTED_DIR="${1:-/tmp/src/extensions}"

echo "JBOSS_HOME=${JBOSS_HOME}"
echo "INJECTED_DIR=${INJECTED_DIR}"

# 1) PostgreSQL 모듈 설치 (module.xml + jar)
if [[ -d "${INJECTED_DIR}/modules" ]]; then
  echo "Installing custom modules from ${INJECTED_DIR}/modules -> ${JBOSS_HOME}/modules"
  cp -a "${INJECTED_DIR}/modules/." "${JBOSS_HOME}/modules/"
else
  echo "ERROR: ${INJECTED_DIR}/modules not found. Expected modules/org/postgresql/main/..."
  exit 1
fi

# 2) 드라이버 등록만 수행 (Datasource는 런타임에 생성)
CLI_FILE="/tmp/register-postgresql-driver.cli"
cat > "${CLI_FILE}" <<'EOF'
embed-server --std-out=echo --server-config=standalone-openshift.xml

if (outcome != success) of /subsystem=datasources/jdbc-driver=postgresql:read-resource()
  /subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)
end-if

stop-embedded-server
EOF

echo "Executing CLI: ${CLI_FILE}"
"${JBOSS_HOME}/bin/jboss-cli.sh" --file="${CLI_FILE}"

echo "=== [extensions] install.sh end (build-time) ==="


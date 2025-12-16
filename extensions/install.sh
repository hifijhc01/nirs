#!/usr/bin/env bash
set -euo pipefail

echo "=== [extensions] install.sh start ==="

JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
INJECTED_DIR="${1:-/tmp/src/extensions}"

echo "JBOSS_HOME=${JBOSS_HOME}"
echo "INJECTED_DIR=${INJECTED_DIR}"

# ------------------------------------------------------------------------------
# 0) 필수 env 확인 (Datasource 생성에 필요)
# ------------------------------------------------------------------------------
: "${POSTGRESQL_URL:?POSTGRESQL_URL is required. ex) jdbc:postgresql://postgres.demo-app.svc:5432/demodb}"
: "${POSTGRESQL_USER:?POSTGRESQL_USER is required}"
: "${POSTGRESQL_PASSWORD:?POSTGRESQL_PASSWORD is required}"

# ------------------------------------------------------------------------------
# 1) PostgreSQL 모듈 설치 (module.xml + jar)
#    - extensions/modules/... 구조를 EAP ${JBOSS_HOME}/modules 로 복사
# ------------------------------------------------------------------------------
if [[ -d "${INJECTED_DIR}/modules" ]]; then
  echo "Installing custom modules from ${INJECTED_DIR}/modules -> ${JBOSS_HOME}/modules"
  # rsync가 없을 수 있으니 cp -a 사용
  cp -a "${INJECTED_DIR}/modules/." "${JBOSS_HOME}/modules/"
else
  echo "ERROR: ${INJECTED_DIR}/modules not found. Expected modules/org/postgresql/main/..."
  exit 1
fi

# ------------------------------------------------------------------------------
# 2) Datasource 생성/드라이버 등록 CLI 작성 (env 값은 install.sh에서 치환)
#    - idempotent: 이미 있으면 skip
# ------------------------------------------------------------------------------
CLI_FILE="/tmp/pgsql-ds.cli"
cat > "${CLI_FILE}" <<EOF
embed-server --std-out=echo --server-config=standalone-openshift.xml

# ---- PostgreSQL driver 등록(없을 때만) ----
if (outcome != success) of /subsystem=datasources/jdbc-driver=postgresql:read-resource()
  /subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)
end-if

# ---- KitchensinkDS 생성(없을 때만) ----
if (outcome != success) of /subsystem=datasources/data-source=KitchensinkDS:read-resource()
  data-source add \\
    --name=KitchensinkDS \\
    --jndi-name=java:jboss/datasources/KitchensinkDS \\
    --driver-name=postgresql \\
    --connection-url=${POSTGRESQL_URL} \\
    --user-name=${POSTGRESQL_USER} \\
    --password=${POSTGRESQL_PASSWORD} \\
    --min-pool-size=5 \\
    --max-pool-size=20 \\
    --check-valid-connection-sql="SELECT 1" \\
    --background-validation=true \\
    --background-validation-millis=60000
end-if

# ---- 연결 테스트 ----
/subsystem=datasources/data-source=KitchensinkDS:test-connection-in-pool

stop-embedded-server
EOF

echo "Executing CLI: ${CLI_FILE}"
"${JBOSS_HOME}/bin/jboss-cli.sh" --file="${CLI_FILE}"

echo "=== [extensions] install.sh end ==="


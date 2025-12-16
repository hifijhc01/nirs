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


# 2) WAR 찾기
# kitchensink-only repo라면 target/*.war가 일반적
WAR_CANDIDATES=(
  "${SRC_DIR}/target"/*.war
  "${SRC_DIR}/kitchensink/target"/*.war
)

WAR_FILE=""
for f in "${WAR_CANDIDATES[@]}"; do
  if [ -f "$f" ]; then
    WAR_FILE="$f"
    break
  fi
done

if [ -z "${WAR_FILE}" ]; then
  echo "[extensions] ERROR: war file not found under:"
  printf " - %s\n" "${WAR_CANDIDATES[@]}"
  echo "[extensions] Hint: check build output path"
  exit 1
fi

echo "[extensions] Found WAR: ${WAR_FILE}"

# 3) /deployments 로 강제 배포
# 루트(/)로 서비스하려면 ROOT.war
cp -vf "${WAR_FILE}" /deployments/ROOT.war

# 배포 트리거 파일(선택이지만 명확함)
touch /deployments/ROOT.war.dodeploy




echo "=== [extensions] install.sh end (build-time) ==="


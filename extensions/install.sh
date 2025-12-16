#!/usr/bin/env bash
set -euo pipefail

echo "=== [extensions] install.sh start (build-time) ==="

JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
INJECTED_DIR="${INJECTED_DIR:-/tmp/src/extensions}"

# S2I 소스 루트는 보통 /tmp/src
SRC_DIR="${SRC_DIR:-/tmp/src}"

echo "JBOSS_HOME=${JBOSS_HOME}"
echo "INJECTED_DIR=${INJECTED_DIR}"
echo "SRC_DIR=${SRC_DIR}"

# (기존 로직 유지) custom modules 설치
if [ -d "${INJECTED_DIR}/modules" ]; then
  echo "Installing custom modules from ${INJECTED_DIR}/modules -> ${JBOSS_HOME}/modules"
  cp -a "${INJECTED_DIR}/modules/." "${JBOSS_HOME}/modules/"
fi

# (기존 로직 유지) postgresql driver 등록 CLI 실행 (있을 때만)
if [ -f "${INJECTED_DIR}/register-postgresql-driver.cli" ]; then
  echo "Executing CLI: ${INJECTED_DIR}/register-postgresql-driver.cli"
  "${JBOSS_HOME}/bin/jboss-cli.sh" --file="${INJECTED_DIR}/register-postgresql-driver.cli" || true
fi

# ---- 여기부터: WAR를 /deployments 로 배포 ----
echo "[extensions] locating WAR..."

# kitchensink-only repo라면 보통 /tmp/src/target/*.war
# 혹시 kitchensink/target 구조도 대비
WAR_FILE=""
for f in \
  "${SRC_DIR}/target"/*.war \
  "${SRC_DIR}/kitchensink/target"/*.war
do
  if [ -f "$f" ]; then
    WAR_FILE="$f"
    break
  fi
done

if [ -z "${WAR_FILE}" ]; then
  echo "[extensions] ERROR: WAR not found. candidates:"
  echo " - ${SRC_DIR}/target/*.war"
  echo " - ${SRC_DIR}/kitchensink/target/*.war"
  echo "[extensions] listing targets:"
  ls -al "${SRC_DIR}" || true
  ls -al "${SRC_DIR}/target" || true
  ls -al "${SRC_DIR}/kitchensink/target" || true
  exit 1
fi

echo "[extensions] Found WAR: ${WAR_FILE}"

# /deployments는 EAP S2I에서 배포 디렉토리로 사용됨
cp -vf "${WAR_FILE}" /deployments/ROOT.war
touch /deployments/ROOT.war.dodeploy

echo "=== [extensions] install.sh done (build-time) ==="


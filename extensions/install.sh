#!/usr/bin/env bash
set -euo pipefail

echo "=== [extensions] install.sh start (build-time) ==="

JBOSS_HOME="${JBOSS_HOME:-/opt/eap}"
INJECTED_DIR="${INJECTED_DIR:-/tmp/src/extensions}"
SRC_DIR="${SRC_DIR:-/tmp/src}"

echo "JBOSS_HOME=${JBOSS_HOME}"
echo "INJECTED_DIR=${INJECTED_DIR}"
echo "SRC_DIR=${SRC_DIR}"

# 1) PostgreSQL module 설치 (modules/ 아래를 통째로 복사)
if [ -d "${INJECTED_DIR}/modules" ]; then
  echo "Installing custom modules from ${INJECTED_DIR}/modules -> ${JBOSS_HOME}/modules"
  cp -a "${INJECTED_DIR}/modules/." "${JBOSS_HOME}/modules/"
fi

# 2) WAR 찾고 /deployments/ROOT.war 로 배포
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
  echo "[extensions] ERROR: WAR not found."
  echo " - ${SRC_DIR}/target/*.war"
  echo " - ${SRC_DIR}/kitchensink/target/*.war"
  ls -al "${SRC_DIR}" || true
  ls -al "${SRC_DIR}/target" || true
  ls -al "${SRC_DIR}/kitchensink/target" || true
  exit 1
fi


# build-time: war deploy
WAR_FILE="$(ls -1 /tmp/src/target/*.war 2>/dev/null | head -n 1 || true)"
if [ -z "$WAR_FILE" ]; then
  WAR_FILE="$(ls -1 /tmp/src/kitchensink/target/*.war 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$WAR_FILE" ]; then
  echo "[extensions] ERROR: war not found under /tmp/src"
  ls -al /tmp/src || true
  ls -al /tmp/src/target || true
  ls -al /tmp/src/kitchensink/target || true
  exit 1
fi


echo "[extensions] Found WAR: ${WAR_FILE}"
cp -vf "${WAR_FILE}" /deployments/ROOT.war
touch /deployments/ROOT.war.dodeploy

echo "=== [extensions] install.sh done (build-time) ==="


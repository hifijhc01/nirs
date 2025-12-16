#!/usr/bin/env bash
set -euo pipefail

injected_dir="$1"
source /usr/local/s2i/install-common.sh

# 1) JDBC 모듈 설치
install_modules "${injected_dir}/modules"

# 2) 드라이버 등록
configure_drivers "${injected_dir}/drivers.env"


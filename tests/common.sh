#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

source ../tools/commons.sh

MP_P_ALL="-"
MP_P_SEL="mariadb postfixadmin"

set -x
if run_step "${MP_P_ALL}" "${MP_P_SEL}" "nginx roundcubemail postfixadmin pm"; then
  echo "A"
fi

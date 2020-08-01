#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

#trap 'trap_exit ${?} ${LINENO}' ERR
#trap 'trap_exit ${?} ${LINENO} ${BASH_LINENO} ${FUNCNAME[*]} ${BASH_SOURCE[*]}' EXIT

function trap_exit() {
  if [[ "$1" != "0" ]]; then
    echo "Error   : ${1} at ${2} $@"
    echo "Function: ${FUNCNAME[1]}"
    echo "File    : ${BASH_SOURCE[1]}"
    echo "Line    : ${LINENO}"
    echo "Caller  : ${BASH_LINENO[1]}"
    exit 1
  fi
}

declare THIS_PATH
THIS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"

declare CONFIG_FILE
CONFIG_FILE="${THIS_PATH}/config.yml"

declare APPS_DIR
APPS_DIR="${THIS_PATH}/apps"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/names.sh
source "${THIS_PATH}/tools/names.sh"
# shellcheck source=./tools/help.sh
source "${THIS_PATH}/tools/help.sh"
# shellcheck source=./tools/launch.sh
source "${THIS_PATH}/tools/launch.sh"

declare MP_P_ALL="true"
declare MP_P_SEL="-"
declare MP_DOCKER_COMMAND="up --detach"
declare MP_PARAMS

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  -h|--help)
    print_run_help
    exit 0
    ;;
  -l|--list)
    print_run_services
    exit 0
    ;;
  -R|--restart)
    MP_DOCKER_COMMAND="restart"
    shift 1
    ;;
  -s|--service)
    MP_P_ALL="-"
    MP_P_SEL+="${2}"
    MP_PARAMS+=" --service ${2}"
    shift 2
    ;;
  *)
    echo "Invalid option: '${1}'"
    exit 1
    ;;
  esac
done

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  run_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "antivirus"; then
  run_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "fail2ban"; then
  run_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail opendkim opendmarc spf"; then
  run_mail "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "web"; then
  run_web "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi
#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

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

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  -h|--help)
    print_stop_help
    exit 0
    ;;
  -l|--list)
    print_stop_services
    exit 0
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

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "web"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "web"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail opendkim opendmarc spf"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mail"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mariadb"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "fail2ban"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "fail2ban"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "antivirus"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "antivirus"
fi
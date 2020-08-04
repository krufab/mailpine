#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare TOOLS_PATH
TOOLS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"
declare MAIN_PATH
MAIN_PATH="$(dirname "${TOOLS_PATH}")"

declare APPS_DIR="${MAIN_PATH}/apps"
declare CONFIG_FILE="${MAIN_PATH}/config.yml"

# shellcheck source=tools/commons.sh
source "${TOOLS_PATH}/commons.sh"
# shellcheck source=tools/names.sh
source "${TOOLS_PATH}/names.sh"
# shellcheck source=tools/help.sh
source "${TOOLS_PATH}/help.sh"
# shellcheck source=tools/launch.sh
source "${TOOLS_PATH}/launch.sh"

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
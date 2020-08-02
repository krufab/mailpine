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
declare DATA_DIR
DATA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.data-dir')")"
declare LOG_DIR
LOG_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.log-dir')")"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/domains.sh"
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
declare VERBOSE="${VERBOSE:-$(get_verbose_value "${CONFIG_FILE}")}"


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

  # shellcheck source=./tools/web/apps_web_services.sh
  source "${THIS_PATH}/tools/web/apps_web_services.sh"
  configure_web_services "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"

  run_web "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail postfix opendkim opendmarc spf"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mail"

  # shellcheck source=./tools/mail/apps_mail.sh
  source "${THIS_PATH}/tools/mail/apps_mail.sh"
  configure_mail "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  # shellcheck source=./tools/mail/opendkim.sh
  source "${THIS_PATH}/tools/mail/opendkim.sh"
  configure_opendkim "${CONFIG_FILE}" "${DATA_DIR}/opendkim"
  # shellcheck source=./tools/mail/opendmarc.sh
  source "${THIS_PATH}/tools/mail/opendmarc.sh"
  configure_opendmarc "${CONFIG_FILE}"
  # shellcheck source=./tools/mail/spf.sh
  source "${THIS_PATH}/tools/mail/spf.sh"
  configure_spf "${CONFIG_FILE}"

  run_mail "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mariadb"

  # shellcheck source=./tools/mariadb/apps_mariadb.sh
  source "${THIS_PATH}/tools/mariadb/apps_mariadb.sh"
  configure_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"

  run_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "fail2ban"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "fail2ban"

  # shellcheck source=./tools/fail2ban/apps_fail2ban.sh
  source "${THIS_PATH}/tools/fail2ban/apps_fail2ban.sh"
  configure_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"

  run_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "antivirus"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "antivirus"

  # shellcheck source=./tools/antivirus/apps_antivirus.sh
  source "${THIS_PATH}/tools/antivirus/apps_antivirus.sh"
  configure_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"

  run_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

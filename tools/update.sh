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

declare DATA_DIR
DATA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.data')")"
declare LOG_DIR
LOG_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.log')")"
declare EXTRA_DIR
EXTRA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.extra')")"

# shellcheck source=tools/commons.sh
source "${TOOLS_PATH}/commons.sh"
# shellcheck source=tools/commons.sh
source "${TOOLS_PATH}/domains.sh"
# shellcheck source=tools/names.sh
source "${TOOLS_PATH}/names.sh"
# shellcheck source=tools/help.sh
source "${TOOLS_PATH}/help.sh"
# shellcheck source=tools/launch.sh
source "${TOOLS_PATH}/launch.sh"

declare MP_P_ALL="true"
declare MP_P_SEL="-"
declare MP_DOCKER_COMMAND="up --detach"
declare MP_PARAMS
declare VERBOSE="${VERBOSE:-$(get_verbose_value "${CONFIG_FILE}")}"


while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  -h|--help)
    print_update_help
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

  # shellcheck source=tools/web/apps_web_services.sh
  source "${TOOLS_PATH}/web/apps_web_services.sh"
  configure_web_services "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}" "${EXTRA_DIR}"

  run_web "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail postfix opendkim opendmarc spf"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mail"

  # shellcheck source=tools/mail/apps_mail.sh
  source "${TOOLS_PATH}/mail/apps_mail.sh"
  configure_mail "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  # shellcheck source=tools/mail/opendkim.sh
  source "${TOOLS_PATH}/mail/opendkim.sh"
  configure_opendkim "${CONFIG_FILE}" "${DATA_DIR}/opendkim"
  # shellcheck source=tools/mail/opendmarc.sh
  source "${TOOLS_PATH}/mail/opendmarc.sh"
  configure_opendmarc "${CONFIG_FILE}"
  # shellcheck source=tools/mail/spf.sh
  source "${TOOLS_PATH}/mail/spf.sh"
  configure_spf "${CONFIG_FILE}"

  run_mail "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "mariadb"

  # shellcheck source=tools/mariadb/apps_mariadb.sh
  source "${TOOLS_PATH}/mariadb/apps_mariadb.sh"
  configure_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"

  run_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "fail2ban"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "fail2ban"

  # shellcheck source=tools/fail2ban/apps_fail2ban.sh
  source "${TOOLS_PATH}/fail2ban/apps_fail2ban.sh"
  configure_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"

  run_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "antivirus"; then
  stop_service "${CONFIG_FILE}" "${APPS_DIR}" "antivirus"

  # shellcheck source=tools/antivirus/apps_antivirus.sh
  source "${TOOLS_PATH}/antivirus/apps_antivirus.sh"
  configure_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"

  run_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

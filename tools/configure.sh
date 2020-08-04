#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

if ! command -v yq &>/dev/null; then
  echo "You need to have yq installed"
  echo "Check https://github.com/mikefarah/yq"
  exit 1
fi

if ! readlink --help | grep -q -- '-f, --canonicalize'; then
  echo "Your system doesn't support 'readlink -f'"
  echo "You need to have coreutils installed and in the path"
  echo "Check https://stackoverflow.com/a/4031502/8989626"
  exit 1
fi

if ! command -v nc &>/dev/null; then
  echo "You need to have nc installed"
  echo "Install it according to your OS"
  exit 1
fi

if ! sed --help | grep -q -- '--follow-symlinks'; then
  echo "Your system doesn't support 'sed --follow-symlinks'"
  echo "You need to have GNU sed installed and in the path"
  echo "Install it according to your OS"
  echo "On mac: brew install gnu-sed"
  exit 1
fi

#trap 'trap_exit ${?} ${LINENO}' ERR
#trap 'trap_exit ${?} ${LINENO} ${BASH_LINENO} ${FUNCNAME[*]} ${BASH_SOURCE[*]}' EXIT

function trap_exit() {
  if [[ "$1" != "0" ]]; then
    echo "Error   : ${1} at ${2} ${*}"
    echo "Function: ${FUNCNAME[1]}"
    echo "File    : ${BASH_SOURCE[1]}"
    echo "Line    : ${LINENO}"
    echo "Caller  : ${BASH_LINENO[1]}"
    exit 1
  fi
}

function trap_error() {
  if [[ "$1" != "0" ]]; then
    echo "Error   : ${1} at ${2} ${*}"
    echo "Function: ${4}"
    echo "File    : ${5}"
    echo "Line    : ${2}"
    echo "Caller  : ${3}"
    exit 1
  fi
}

declare MIN_CONFIG_VERSION="1.1"

declare TOOLS_PATH
TOOLS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"
declare MAIN_PATH
MAIN_PATH="$(dirname "${TOOLS_PATH}")"

# shellcheck source=tools/commons.sh
source "${TOOLS_PATH}/commons.sh"
# shellcheck source=tools/domains.sh
source "${TOOLS_PATH}/domains.sh"
# shellcheck source=tools/names.sh
source "${TOOLS_PATH}/names.sh"
# shellcheck source=tools/help.sh
source "${TOOLS_PATH}/help.sh"
# shellcheck source=tools/prepare_folders.sh
source "${TOOLS_PATH}/prepare_folders.sh"

declare CONFIG_FILE="${MAIN_PATH}/config.yml"

declare VERBOSE="${VERBOSE:-$(get_verbose_value "${CONFIG_FILE}")}"

check_config_version "${CONFIG_FILE}" "${MIN_CONFIG_VERSION}"

declare APPS_DIR="${MAIN_PATH}/apps"
declare DATA_DIR
DATA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.data')")"
declare LOG_DIR
LOG_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.log')")"
declare EXTRA_DIR
EXTRA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.folders.extra')")"

declare MP_P_ALL="true"
declare MP_P_SEL="-"

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  -d|--debug)
    shift 1
    ;;
  -h|--help)
    print_configuration_help
    exit 0
    ;;
  -l|--list)
    print_configuration_services
    exit 0
    ;;
  -s|--service)
    MP_P_ALL="-"
    MP_P_SEL+="${2}"
    shift 2
    ;;
  -v|--verbose)
    shift 1
    ;;
  *)
    echo "Invalid option: '${1}'"
    exit 1
    ;;
  esac
done

prepare_folders "${DATA_DIR}" "${LOG_DIR}"

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mailpine"; then
  # shellcheck source=tools/docker.sh
  source "${TOOLS_PATH}/docker.sh"
  check_mailpine_tools
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "certificates"; then
  # shellcheck source=tools/certificates.sh
  source "${TOOLS_PATH}/certificates.sh"
  configure_certificates "${CONFIG_FILE}" "${DATA_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "opendkim"; then
  # shellcheck source=tools/mail/opendkim.sh
  source "${TOOLS_PATH}/mail/opendkim.sh"
  configure_opendkim "${CONFIG_FILE}" "${DATA_DIR}/opendkim"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "opendmarc"; then
  # shellcheck source=tools/mail/opendmarc.sh
  source "${TOOLS_PATH}/mail/opendmarc.sh"
  configure_opendmarc "${CONFIG_FILE}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "spf"; then
  # shellcheck source=tools/mail/spf.sh
  source "${TOOLS_PATH}/mail/spf.sh"
  configure_spf "${CONFIG_FILE}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "antivirus"; then
  # shellcheck source=tools/antivirus/apps_antivirus.sh
  source "${TOOLS_PATH}/antivirus/apps_antivirus.sh"
  configure_antivirus "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "fail2ban"; then
  # shellcheck source=tools/fail2ban/apps_fail2ban.sh
  source "${TOOLS_PATH}/fail2ban/apps_fail2ban.sh"
  configure_fail2ban "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  # shellcheck source=tools/mariadb/apps_mariadb.sh
  source "${TOOLS_PATH}/mariadb/apps_mariadb.sh"
  configure_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail"; then
  # shellcheck source=tools/mail/apps_mail.sh
  source "${TOOLS_PATH}/mail/apps_mail.sh"
  configure_mail "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "web"; then
  # shellcheck source=tools/web/apps_web_services.sh
  source "${TOOLS_PATH}/web/apps_web_services.sh"
  configure_web_services "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}" "${LOG_DIR}" "${EXTRA_DIR}"
fi

echo_ok "Configuration completed successfully"

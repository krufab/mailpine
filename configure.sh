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
    echo "Error   : ${1} at ${2} $@"
    echo "Function: ${FUNCNAME[1]}"
    echo "File    : ${BASH_SOURCE[1]}"
    echo "Line    : ${LINENO}"
    echo "Caller  : ${BASH_LINENO[1]}"
    exit 1
  fi
}

function trap_error() {
  if [[ "$1" != "0" ]]; then
    echo "Error   : ${1} at ${2} $@"
    echo "Function: ${4}"
    echo "File    : ${5}"
    echo "Line    : ${2}"
    echo "Caller  : ${3}"
    exit 1
  fi
}

declare MIN_CONFIG_VERSION="1.1"

declare THIS_PATH
THIS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/domains.sh
source "${THIS_PATH}/tools/domains.sh"
# shellcheck source=./tools/names.sh
source "${THIS_PATH}/tools/names.sh"
# shellcheck source=./tools/prepare_folders.sh
source "${THIS_PATH}/tools/prepare_folders.sh"

declare CONFIG_FILE="${THIS_PATH}/config.yml"

declare VERBOSE="${VERBOSE:-$(get_verbose_value "${CONFIG_FILE}")}"

check_config_version "${CONFIG_FILE}" "${MIN_CONFIG_VERSION}"

declare APPS_DIR="${THIS_PATH}/apps"
declare DATA_DIR
DATA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.data-dir')")"
declare LOGS_DIR
LOGS_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.logs-dir')")"

declare MP_P_ALL="true"
declare MP_P_SEL="-"
declare MP_RUN MP_RESTART
declare MP_PARAMS

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  -d|--debug)
    shift 1
    ;;
  -R|--restart)
    MP_RESTART="true"
    MP_PARAMS+=" --restart"
    shift 1
    ;;
  -r|--run)
    MP_RUN="true"
    shift 1
    ;;
  -s|--service)
    MP_P_ALL="-"
    MP_P_SEL+="${2}"
    MP_PARAMS+=" --service ${2}"
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

prepare_folders "${DATA_DIR}" "${LOGS_DIR}"

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mailpine"; then
  # shellcheck source=./tools/docker.sh
  source "${THIS_PATH}/tools/docker.sh"
  check_mailpine_tools
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "certificates"; then
  # shellcheck source=./tools/certificates.sh
  source "${THIS_PATH}/tools/certificates.sh"
  configure_certificates "${CONFIG_FILE}" "${DATA_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "opendkim"; then
  # shellcheck source=./tools/mail/opendkim.sh
  source "${THIS_PATH}/tools/mail/opendkim.sh"
  configure_opendkim "${CONFIG_FILE}" "${DATA_DIR}/opendkim"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "opendmarc"; then
  # shellcheck source=./tools/mail/opendmarc.sh
  source "${THIS_PATH}/tools/mail/opendmarc.sh"
  configure_opendmarc "${CONFIG_FILE}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "spf"; then
  # shellcheck source=./tools/mail/spf.sh
  source "${THIS_PATH}/tools/mail/spf.sh"
  configure_spf "${CONFIG_FILE}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mariadb"; then
  # shellcheck source=./tools/mariadb/apps_mariadb.sh
  source "${THIS_PATH}/tools/mariadb/apps_mariadb.sh"
  configure_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail"; then
  # shellcheck source=./tools/mail/apps_mail.sh
  source "${THIS_PATH}/tools/mail/apps_mail.sh"
  configure_mail "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "web"; then
  # shellcheck source=./tools/web/apps_web_services.sh
  source "${THIS_PATH}/tools/web/apps_web_services.sh"
  configure_web_services "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
fi

echo_ok "Configuration completed successfully"

if [[ "${MP_RUN:-}" == "true" ]] || [[ "${MP_RESTART:-}" == "true" ]]; then
  ./run.sh ${MP_PARAMS}
fi
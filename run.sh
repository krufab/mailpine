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

function run_mariadb() {
  local CONFIG_FILE="${1}"
  local APPS_DIR="${2}"
  local MP_DOCKER_COMMAND="${3}"
  local IS_MARIADB_ENABLED PROFILE

  IS_MARIADB_ENABLED="$(yq r "${CONFIG_FILE}" 'services.database.internal')"
  if [[ "${IS_MARIADB_ENABLED}" = "true" ]]; then
    echo_ok "Starting mariadb"
    (
      cd apps/mariadb/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mariadb")"
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND}
    )
  fi
}

function run_mail() {
  local CONFIG_FILE="${1}"
  local APPS_DIR="${2}"
  local MP_DOCKER_COMMAND="${3}"
  local PROFILE

  echo_ok "Starting mail"
  (
    cd apps/mail/
    PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mail")"
    if [[ "${MP_DOCKER_COMMAND}" == "restart" ]]; then
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND}
    else
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} --build
    fi
  )
}

function run_web() {
  local CONFIG_FILE="${1}"
  local APPS_DIR="${2}"
  local MP_DOCKER_COMMAND="${3}"
  local PROFILE
  local RESTART_NGINX="-"

  IS_ROUNDCUBEMAIL_ENABLED="$(yq r "${CONFIG_FILE}" 'services.web_services.roundcubemail.enabled')"
  if [[ "${IS_ROUNDCUBEMAIL_ENABLED}" == "true" ]]; then
    RESTART_NGINX="true"
    echo_ok "Starting roundcube"
    (
      cd apps/web/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} mail
    )
  fi

  IS_POSTFIXADMIN_ENABLED="$(yq r "${CONFIG_FILE}" 'services.web_services.postfixadmin.enabled')"
  if [[ "${IS_POSTFIXADMIN_ENABLED}" == "true" ]]; then
    RESTART_NGINX="true"
    echo_ok "Starting postfixadmin"
    (
      cd apps/web/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
      if [[ "${MP_DOCKER_COMMAND}" == "restart" ]]; then
        docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} pa
      else
        docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} --build pa
      fi
    )
  fi

  IS_PHPMYADMIN_ENABLED="$(yq r "${CONFIG_FILE}" 'services.web_services.phpmyadmin.enabled')"
  if [[ "${IS_PHPMYADMIN_ENABLED}" == "true" ]]; then
    RESTART_NGINX="true"
    echo_ok "Starting phpmyadmin"
    (
      cd apps/web/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} pma
    )
  fi

  if [[ "${RESTART_NGINX}" == "true" ]]; then
    echo_ok "Starting nginx"
    (
      cd apps/web/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
      docker-compose --project-name "${PROFILE}" ${MP_DOCKER_COMMAND} nginx
    )
  fi
}

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

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "mail opendkim opendmarc spf"; then
  run_mail "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi

if run_step "${MP_P_ALL}" "${MP_P_SEL}" "web"; then
  run_web "${CONFIG_FILE}" "${APPS_DIR}" "${MP_DOCKER_COMMAND}"
fi
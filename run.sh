#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare -r THIS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"

declare CONFIG_FILE="${THIS_PATH}/config.yml"

declare APPS_DIR="${THIS_PATH}/apps"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/names.sh
source "${THIS_PATH}/tools/names.sh"

function run_traefik() {
  local CONFIG_FILE APPS_DIR
  local IS_TRAEFIK_ENABLED PROFILE

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"

  IS_TRAEFIK_ENABLED="$(yq r "${CONFIG_FILE}" 'services.traefik.enabled')"
  if [[ "${IS_TRAEFIK_ENABLED}" = "true" ]]; then
    (
      cd apps/traefik/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "traefik")"
      docker-compose --project-name "${PROFILE}" up --detach
    )
  fi
}

function run_mariadb() {
  local CONFIG_FILE APPS_DIR
  local IS_MARIADB_ENABLED PROFILE

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"

  IS_MARIADB_ENABLED="$(yq r "${CONFIG_FILE}" 'services.database.internal')"
  if [[ "${IS_MARIADB_ENABLED}" = "true" ]]; then
    (
      cd apps/mariadb/
      PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mariadb")"
      docker-compose --project-name "${PROFILE}" up --detach
    )
  fi
}

function run_mail() {
  local CONFIG_FILE APPS_DIR
  local PROFILE

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"

  (
    cd apps/mail/
    PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mail")"
    docker-compose --project-name "${PROFILE}" up --build --detach
  )
}

function run_web() {
  local CONFIG_FILE APPS_DIR
  local PROFILE

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"

  (
    cd apps/web/
    PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
    docker-compose --project-name "${PROFILE}" up --build --detach
  )
}

run_traefik "${CONFIG_FILE}" "${APPS_DIR}"

run_mariadb "${CONFIG_FILE}" "${APPS_DIR}"

run_mail "${CONFIG_FILE}" "${APPS_DIR}"

run_web "${CONFIG_FILE}" "${APPS_DIR}"

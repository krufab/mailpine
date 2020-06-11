#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function process_mail() {
  local CONFIG_FILE APPS_DIR DATA_DIR
  local APP_DIR

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"
  DATA_DIR="${3}"

  APP_DIR="${APPS_DIR}/mail"

  copy_template "${APP_DIR}"

  (
    unset TZ
    local MP_DATABASE_PASSWORD MP_DOMAIN MP_FQDN_MAIL

    source "${APP_DIR}/.env"

    set_MP_DATA_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${DATA_DIR}"
    set_TZ_variable "${CONFIG_FILE}" "${APP_DIR}"

    MP_DATABASE_HOST="$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mariadb" "mariadb")"
    MP_DATABASE_PASSWORD="$(grep 'MP_PASSWORD_POSTFIX=' "${APPS_DIR}/mariadb/.env")"
    MP_DOMAIN="$(get_MP_DOMAIN "${CONFIG_FILE}")"
    MP_FQDN_MAIL="$(get_MP_FQDN_x "${CONFIG_FILE}" "mail")"

    sed -i \
      -e "s|^MP_DATABASE_HOST=.*$|MP_DATABASE_HOST=${MP_DATABASE_HOST}|g" \
      -e "s|^MP_DATABASE_PASSWORD=.*$|MP_DATABASE_PASSWORD=${MP_DATABASE_PASSWORD#*=}|g" \
      -e "s|^MP_DOMAIN=.*$|MP_DOMAIN=${MP_DOMAIN}|g" \
      -e "s|^MP_FQDN_MAIL=.*$|MP_FQDN_MAIL=${MP_FQDN_MAIL}|g" \
      "${APP_DIR}/.env"

  )
}

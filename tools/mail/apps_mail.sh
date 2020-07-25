#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_mail() {
  local CONFIG_FILE="${1}"
  local APPS_DIR="${2}"
  local DATA_DIR="${3}"
  local LOG_DIR="${4}"

  local APP_DIR="${APPS_DIR}/mail"

  copy_template "${APP_DIR}"

  (
    unset TZ
    local MP_DATABASE_PASSWORD MP_DOMAIN MP_FQDN_MAIL

    source "${APP_DIR}/.env"

    set_MP_DATA_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${DATA_DIR}"
    set_MP_LOG_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${LOG_DIR}"
    set_TZ_variable "${CONFIG_FILE}" "${APP_DIR}"

    MP_DATABASE_HOST="$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mariadb" "mariadb")"
    MP_DATABASE_PASSWORD="$(grep 'MP_PASSWORD_POSTFIX=' "${APPS_DIR}/mariadb/.env")"
    MP_DOMAIN="$(get_MP_DOMAIN "${CONFIG_FILE}")"
    MP_FQDN_MAIL="$(get_MP_FQDN_x "${CONFIG_FILE}" "smtp")"

    MP_MAIL_NETWORK="$(get_mynetwork "${CONFIG_FILE}")"

    sed -i \
      -e "s|^MP_DATABASE_HOST=.*$|MP_DATABASE_HOST=${MP_DATABASE_HOST}|g" \
      -e "s|^MP_DATABASE_PASSWORD=.*$|MP_DATABASE_PASSWORD=${MP_DATABASE_PASSWORD#*=}|g" \
      -e "s|^MP_DOMAIN=.*$|MP_DOMAIN=${MP_DOMAIN}|g" \
      -e "s|^MP_FQDN_MAIL=.*$|MP_FQDN_MAIL=${MP_FQDN_MAIL}|g" \
      -e "s|^MP_MAIL_NETWORK=.*$|MP_MAIL_NETWORK=${MP_MAIL_NETWORK}|g" \
      "${APP_DIR}/.env"
  )
}

function get_mynetwork() {
  local CONFIG_FILE="${1}"
  local network subnet

  network="$(get_MP_D_NETWORK_x "${CONFIG_FILE}" "mail")"
  if docker network ls | grep -q "${network}"; then
    subnet="$(extract_subnet "${network}")"
  else
    docker network create "${network}"
    subnet="$(extract_subnet "${network}")"
  fi

  echo "${subnet}"
}

function extract_subnet {
  local network="${network}"
  docker network inspect "${network}" | jq -c -r '.[] | .IPAM.Config[0].Subnet'
}
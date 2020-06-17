#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_mariadb() {
  local CONFIG_FILE APPS_DIR DATA_DIR
  local APP_DIR

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"
  DATA_DIR="${3}"

  APP_DIR="${APPS_DIR}/mariadb"

  copy_template "${APP_DIR}"

  (
    unset TZ
    local PASSWORD TIMEZONE

    source "${APP_DIR}/.env"

    set_MP_DATA_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${DATA_DIR}"
    set_TZ_variable "${CONFIG_FILE}" "${APP_DIR}"

    if [[ -z "${MYSQL_ROOT_PASSWORD}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MYSQL_ROOT_PASSWORD=.*$|MYSQL_ROOT_PASSWORD=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    if [[ -z "${MP_PASSWORD_DOVECOT}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MP_PASSWORD_DOVECOT=.*$|MP_PASSWORD_DOVECOT=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    if [[ -z "${MP_PASSWORD_PMA}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MP_PASSWORD_PMA=.*$|MP_PASSWORD_PMA=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    if [[ -z "${MP_PASSWORD_POSTFIX}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MP_PASSWORD_POSTFIX=.*$|MP_PASSWORD_POSTFIX=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    if [[ -z "${MP_PASSWORD_POSTFIXADMIN}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MP_PASSWORD_POSTFIXADMIN=.*$|MP_PASSWORD_POSTFIXADMIN=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    if [[ -z "${MP_PASSWORD_ROUNDCUBE}" ]]; then
      PASSWORD="$(openssl rand -base64 32)"
      sed -i -e "s|^MP_PASSWORD_ROUNDCUBE=.*$|MP_PASSWORD_ROUNDCUBE=${PASSWORD}|g" "${APP_DIR}/.env"
    fi

    source "${APP_DIR}/.env"
    sed -i \
      -e "s|@password_roundcube@|'${MP_PASSWORD_ROUNDCUBE}'|g" \
      -e "s|@password_postfix@|'${MP_PASSWORD_POSTFIX}'|g" \
      -e "s|@password_postfixadmin@|'${MP_PASSWORD_POSTFIXADMIN}'|g" \
      -e "s|@password_dovecot@|'${MP_PASSWORD_DOVECOT}'|g" \
      -e "s|@password_pma@|'${MP_PASSWORD_PMA}'|g" \
      "${APP_DIR}/rootfs/docker-entrypoint-initdb.d/init-db.sql"
  )
}

#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_traefik() {
  local CONFIG_FILE APPS_DIR DATA_DIR
  local APP_DIR

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"
  DATA_DIR="${3}"

  APP_DIR="${APPS_DIR}/traefik"

  copy_template "${APP_DIR}"

  (
    unset TZ
    local ACME_EMAIL STAGING CASERVER
    local DASHBOARD_ENABLED

    source "${APP_DIR}/.env"

    set_MP_DATA_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${DATA_DIR}"
    set_TZ_variable "${CONFIG_FILE}" "${APP_DIR}"

    ACME_EMAIL="$(yq r "${CONFIG_FILE}" 'config[acme.sh].account_email')"

    STAGING="$(yq r "${CONFIG_FILE}" 'config[acme.sh].staging')"
    if [[ "${STAGING}" = "true" ]]; then
      CASERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
    else
      CASERVER="https://acme-v02.api.letsencrypt.org/directory"
    fi

    DASHBOARD_ENABLED="$(yq r "${CONFIG_FILE}" 'services.traefik.dashboard.enabled')"
    MP_FQDN_TRAEFIK_DASHBOARD="$(get_MP_FQDN_x "${CONFIG_FILE}" "traefik")"

    sed -i \
      -e "s|^MP_FQDN_TRAEFIK_DASHBOARD=.*$|MP_FQDN_TRAEFIK_DASHBOARD=${MP_FQDN_TRAEFIK_DASHBOARD}|g" \
      -e "s|^MP_TRAEFIK_ACME_EMAIL=.*$|MP_TRAEFIK_ACME_EMAIL=${ACME_EMAIL}|g" \
      -e "s|^MP_TRAEFIK_CASERVER=.*$|MP_TRAEFIK_CASERVER=${CASERVER}|g" \
      -e "s|^MP_TRAEFIK_DASHBOARD_ENABLED=.*$|MP_TRAEFIK_DASHBOARD_ENABLED=${DASHBOARD_ENABLED}|g" \
      -e "s|^MP_TRAEFIK_LOGLEVEL=.*$|MP_TRAEFIK_LOGLEVEL=DEBUG|g" \
      "${APP_DIR}/.env"
  )
}

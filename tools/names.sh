#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function get_MP_DOMAIN() {
  local CONFIG_FILE

  CONFIG_FILE="${1}"

  strip_star "$(extract_main "${CONFIG_FILE}")"
}

function get_HOST_x() {
  local CONFIG_FILE NAME
  local HOST WEB_SERVICE_JSON
  local -a WEB_SERVICES_JSON

  CONFIG_FILE="${1}"
  NAME="${2}"

  case "${NAME}" in
    mail | smtp)
      HOST="$(yq r "${CONFIG_FILE}" "domains[0].${NAME}")"
      ;;
    phpmyadmin | postfixadmin | roundcube)
      readarray -t WEB_SERVICES_JSON < <(yq r -j "${CONFIG_FILE}" | jq -r -c '.services.web_services[]')

      for WEB_SERVICE_JSON in "${WEB_SERVICES_JSON[@]}"; do
        if [[ "${NAME}" = "$(echo -n "${WEB_SERVICE_JSON}" | jq -r -c '.name')" ]]; then
          HOST="$(echo -n "${WEB_SERVICE_JSON}" | jq -r -c '.host')"
        fi
      done
      ;;
    traefik)
      HOST="$(yq r "${CONFIG_FILE}" "services.traefik.dashboard.host")"
      ;;
    *)
      echo_error "Invalid host: ${NAME}"
      exit 1
      ;;
  esac

  if [[ -z "${HOST}" ]]; then
    HOST="${NAME}"
  fi

  echo "${HOST}"
}

function get_MP_FQDN_x() {
  local CONFIG_FILE NAME
  local HOST DOMAIN

  CONFIG_FILE="${1}"
  NAME="${2}"

  DOMAIN="$(get_MP_DOMAIN "${CONFIG_FILE}")"
  HOST="$(get_HOST_x "${CONFIG_FILE}" "${NAME}")"

  echo "${HOST}.${DOMAIN}"
}

function get_MP_D_PREFIX() {
  local CONFIG_FILE

  CONFIG_FILE="${1}"

  yq r "${CONFIG_FILE}" 'config.docker.prefix'
}

function get_MP_D_PROFILE_x() {
  local CONFIG_FILE NAME

  CONFIG_FILE="${1}"
  NAME="${2}"

   echo "$(get_MP_D_PREFIX "${CONFIG_FILE}")${NAME}"
}

function get_MP_D_NETWORK_x() {
  local CONFIG_FILE NAME

  CONFIG_FILE="${1}"
  NAME="${2}"

  echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "${NAME}")_${NAME}"
}

function get_MP_D_CONTAINER_x() {
  local CONFIG_FILE PROFILE NAME

  CONFIG_FILE="${1}"
  PROFILE="${2}"
  NAME="${3}"

  echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "${PROFILE}")_${NAME}_1"
}
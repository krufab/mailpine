#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function get_MP_DOMAIN {
  local CONFIG_FILE="${1}"

  strip_star "$(extract_main "${CONFIG_FILE}")"
}

function get_HOST_x {
  local CONFIG_FILE="${1}"
  local NAME="${2}"

  local HOST

  case "${NAME}" in
    mail | smtp)
      HOST="$(yq r "${CONFIG_FILE}" "domains[0].${NAME}")"
      ;;
    phpmyadmin | postfixadmin | roundcube)
      HOST="$(yq r "${CONFIG_FILE}" "services.web_services.${NAME}.host")"
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

function get_MP_FQDN_x {
  local CONFIG_FILE="${1}"
  local NAME="${2}"

  local HOST DOMAIN

  DOMAIN="$(get_MP_DOMAIN "${CONFIG_FILE}")"
  HOST="$(get_HOST_x "${CONFIG_FILE}" "${NAME}")"

  echo "${HOST}.${DOMAIN}"
}

function get_MP_D_PREFIX {
  local CONFIG_FILE="${1}"

  yq r "${CONFIG_FILE}" 'config.docker.prefix'
}

# Get Mailpine Docker profile name
function get_MP_D_PROFILE_x {
  local CONFIG_FILE="${1}"
  local NAME="${2}"

   echo "$(get_MP_D_PREFIX "${CONFIG_FILE}")${NAME}"
}

function get_MP_D_NETWORK_x {
  local CONFIG_FILE="${1}"
  local NAME="${2}"

  echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "${NAME}")_${NAME}"
}

function get_MP_D_CONTAINER_x {
  local CONFIG_FILE="${1}"
  local PROFILE="${2}"
  local NAME="${3}"

  echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "${PROFILE}")_${NAME}_1"
}
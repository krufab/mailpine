#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function get_MP_DOMAIN {
  local config_file="${1}"

  strip_star "$(extract_main "${config_file}")"
}

function get_HOST_x {
  local config_file="${1}"
  local name="${2}"

  local host

  case "${name}" in
    mail | smtp)
      host="$(yq r "${config_file}" "domains[0].${name}")"
      ;;
    phpmyadmin | postfixadmin | roundcube)
      host="$(yq r "${config_file}" "services.web_services.${name}.host")"
      ;;
    *)
      echo_error "Invalid host: ${name}"
      exit 1
      ;;
  esac

  if [[ -z "${host}" ]]; then
    host="${name}"
  fi

  echo "${host}"
}

function get_MP_FQDN_x {
  local config_file="${1}"
  local name="${2}"

  local domain host

  domain="$(get_MP_DOMAIN "${config_file}")"
  host="$(get_HOST_x "${config_file}" "${name}")"

  echo "${host}.${domain}"
}

function get_MP_D_PREFIX {
  local config_file="${1}"

  yq r "${config_file}" 'config.docker.prefix'
}

# Get Mailpine Docker profile name
function get_MP_D_PROFILE_x {
  local config_file="${1}"
  local name="${2}"

   echo "$(get_MP_D_PREFIX "${config_file}")${name}"
}

function get_MP_D_NETWORK_x {
  local config_file="${1}"
  local name="${2}"

  echo "$(get_MP_D_PROFILE_x "${config_file}" "${name}")_${name}"
}

function get_MP_D_CONTAINER_x {
  local config_file="${1}"
  local profile="${2}"
  local name="${3}"

  echo "$(get_MP_D_PROFILE_x "${config_file}" "${profile}")_${name}_1"
}
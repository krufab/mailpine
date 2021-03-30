#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_mail() {
  echo_ok "Configuring mail"
  local config_file="${1}"
  local apps_dir="${2}"
  local data_dir="${3}"
  local log_dir="${4}"

  local app_dir="${apps_dir}/mail"

  copy_template "${app_dir}"

  (
    unset TZ
    local MP_DATABASE_PASSWORD MP_DOMAIN MP_FQDN_MAIL

    source "${app_dir}/.env"

    set_MP_DATA_DIR_variable "${app_dir}" "${data_dir}"
    set_MP_LOG_DIR_variable "${app_dir}" "${log_dir}"
    set_TZ_variable "${config_file}" "${app_dir}"

    MP_DATABASE_HOST="$(get_MP_D_CONTAINER_x "${config_file}" "mariadb" "mariadb")"
    MP_DATABASE_PASSWORD="$(grep 'MP_PASSWORD_POSTFIX=' "${apps_dir}/mariadb/.env")"
    MP_DOMAIN="$(get_MP_DOMAIN "${config_file}")"
    MP_FQDN_MAIL="$(get_MP_FQDN_x "${config_file}" "smtp")"

    MP_MAIL_NETWORK="$(get_mynetwork "${config_file}")"
    MP_ANTIVIRUS="inet:antivirus:7357"
    if [[ "$(yq r "${config_file}" "services.antivirus.enabled")" != "true" ]]; then
      MP_ANTIVIRUS=""
    fi

    sed -i \
      -e "s|^MP_ANTIVIRUS=.*$|MP_ANTIVIRUS=${MP_ANTIVIRUS}|g" \
      -e "s|^MP_DATABASE_HOST=.*$|MP_DATABASE_HOST=${MP_DATABASE_HOST}|g" \
      -e "s|^MP_DATABASE_PASSWORD=.*$|MP_DATABASE_PASSWORD=${MP_DATABASE_PASSWORD#*=}|g" \
      -e "s|^MP_DOMAIN=.*$|MP_DOMAIN=${MP_DOMAIN}|g" \
      -e "s|^MP_FQDN_MAIL=.*$|MP_FQDN_MAIL=${MP_FQDN_MAIL}|g" \
      -e "s|^MP_MAIL_NETWORK=.*$|MP_MAIL_NETWORK=${MP_MAIL_NETWORK}|g" \
      "${app_dir}/.env"
  )
  echo_ok_verbose "Mail configuration completed successfully"
}

function get_mynetwork() {
  local config_file="${1}"
  local network subnet
set -x
  network="$(get_MP_D_NETWORK_x "${config_file}" "mail")"
  if docker network ls | grep -q "${network}"; then
    subnet="$(extract_subnet "${network}")"
  else
    docker network create "${network}" &>/dev/null
    subnet="$(extract_subnet "${network}")"
  fi
set +x
  echo "${subnet}"
}

function extract_subnet {
  local network="${1}"
  docker network inspect "${network}" | jq -c -r '.[] | .IPAM.Config[0].Subnet'
}
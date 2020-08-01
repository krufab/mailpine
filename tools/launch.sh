#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function stop_service {
  local config_file="${1}"
  local apps_dir="${2}"
  local service="${3}"

  (
    cd "${apps_dir}/${service}"
    profile="$(get_MP_D_PROFILE_x "${config_file}" "${service}")"
    docker-compose --project-name "${profile}" stop
  )
}

function run_mariadb {
  local config_file="${1}"
  local apps_dir="${2}"
  local mp_docker_command="${3}"
  local is_mariadb_enabled profile

  is_mariadb_enabled="$(yq r "${config_file}" 'services.database.internal')"
  if [[ "${is_mariadb_enabled}" = "true" ]]; then
    echo_ok "Starting mariadb"
    (
      cd "${apps_dir}/mariadb"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "mariadb")"
      docker-compose --project-name "${profile}" ${mp_docker_command}
    )
  fi
}


function run_antivirus {
  local config_file="${1}"
  local apps_dir="${2}"
  local mp_docker_command="${3}"

  local service="antivirus"
  local is_service_enabled profile

  is_service_enabled="$(yq r "${config_file}" "services.${service}.enabled")"
  if [[ "${is_service_enabled}" = "true" ]]; then
    echo_ok "Starting ${service}"
    (
      cd "${apps_dir}/${service}"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "${service}")"
      docker-compose --project-name "${profile}" ${mp_docker_command} --build
    )
  fi
}

function run_fail2ban {
  local config_file="${1}"
  local apps_dir="${2}"
  local mp_docker_command="${3}"

  local service="fail2ban"
  local is_service_enabled profile

  is_service_enabled="$(yq r "${config_file}" "services.${service}.enabled")"
  if [[ "${is_service_enabled}" = "true" ]]; then
    echo_ok "Starting ${service}"
    (
      cd "${apps_dir}/${service}"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "${service}")"
      docker-compose --project-name "${profile}" ${mp_docker_command} --build
    )
  fi
}

function run_mail {
  local config_file="${1}"
  local apps_dir="${2}"
  local mp_docker_command="${3}"
  local profile

  echo_ok "Starting mail"
  (
    cd "${apps_dir}/mail"
    profile="$(get_MP_D_PROFILE_x "${config_file}" "mail")"
    if [[ "${mp_docker_command}" == "restart" ]]; then
      docker-compose --project-name "${profile}" ${mp_docker_command}
    else
      docker-compose --project-name "${profile}" ${mp_docker_command} --build
    fi
  )
}

function run_web {
  local config_file="${1}"
  local apps_dir="${2}"
  local mp_docker_command="${3}"
  local profile
  local restart_nginx="-"

  is_roundcubemail_enabled="$(yq r "${config_file}" 'services.web_services.roundcubemail.enabled')"
  if [[ "${is_roundcubemail_enabled}" == "true" ]]; then
    restart_nginx="true"
    echo_ok "Starting roundcube"
    (
      cd "${apps_dir}/web"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "web")"
      docker-compose --project-name "${profile}" ${mp_docker_command} mail
    )
  fi

  is_postfixadmin_enabled="$(yq r "${config_file}" 'services.web_services.postfixadmin.enabled')"
  if [[ "${is_postfixadmin_enabled}" == "true" ]]; then
    restart_nginx="true"
    echo_ok "Starting postfixadmin"
    (
      cd "${apps_dir}/web"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "web")"
      if [[ "${mp_docker_command}" == "restart" ]]; then
        docker-compose --project-name "${profile}" ${mp_docker_command} pa
      else
        docker-compose --project-name "${profile}" ${mp_docker_command} --build pa
      fi
    )
  fi

  is_phpmyadmin_enabled="$(yq r "${config_file}" 'services.web_services.phpmyadmin.enabled')"
  if [[ "${is_phpmyadmin_enabled}" == "true" ]]; then
    restart_nginx="true"
    echo_ok "Starting phpmyadmin"
    (
      cd "${apps_dir}/web"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "web")"
      docker-compose --project-name "${profile}" ${mp_docker_command} pma
    )
  fi

  if [[ "${restart_nginx}" == "true" ]]; then
    echo_ok "Starting nginx"
    (
      cd "${apps_dir}/web"
      profile="$(get_MP_D_PROFILE_x "${config_file}" "web")"
      docker-compose --project-name "${profile}" ${mp_docker_command} nginx
    )
  fi
}

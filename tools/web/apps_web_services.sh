#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_web_services {
  local CONFIG_FILE APPS_DIR DATA_DIR
  local APP_DIR SERVICE_DIR

  CONFIG_FILE="${1}"
  APPS_DIR="${2}"
  DATA_DIR="${3}"
  LOG_DIR="${4}"

  APP_DIR="${APPS_DIR}/web"

  copy_template "${APP_DIR}"

  cp "${APP_DIR}/pa/config.local.template.php" "${APP_DIR}/pa/config.local.php"
  cp "${APP_DIR}/pma/config.user.inc.template.php" "${APP_DIR}/pma/config.user.inc.php"
  cp "${APP_DIR}/roundcubemail/config.inc.template.php" "${APP_DIR}/roundcubemail/config.inc.php"

  (
    unset TZ

    source "${APP_DIR}/.env"

    set_MP_DATA_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${DATA_DIR}"
    set_MP_LOG_DIR_variable "${CONFIG_FILE}" "${APP_DIR}" "${LOG_DIR}"
    set_TZ_variable "${CONFIG_FILE}" "${APP_DIR}"

    docker run --rm -v "${LOG_DIR}:/tmp/log" \
      mailpine-tools:latest \
      bash -ce "chown -R 82:82 /tmp/log/roundcubemail"

    MP_DOMAIN="$(get_MP_DOMAIN "${CONFIG_FILE}")"
    MP_FQDN_POSTFIXADMIN="$(get_MP_FQDN_x "${CONFIG_FILE}" "postfixadmin")"
    if [[ -z "${MP_PMA_BLOWFISH_SECRET}" ]]; then
      MP_PMA_BLOWFISH_SECRET="$(openssl rand -base64 32)"
    fi

    DB_HOST="$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mariadb" "mariadb")"
    POSTFIXADMIN="$(grep 'MP_PASSWORD_POSTFIXADMIN=' "${APPS_DIR}/mariadb/.env")"
    ROUNDCUBE="$(grep 'MP_PASSWORD_ROUNDCUBE=' "${APPS_DIR}/mariadb/.env")"
    PA_SMTP_SERVER="$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mail" "mail")"
    PA_SMTP_CLIENT="$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "web" "pa")"
    FQDN_MAIL="$(get_MP_FQDN_x "${CONFIG_FILE}" "mail")"
    FQDN_SMTP="$(get_MP_FQDN_x "${CONFIG_FILE}" "smtp")"

    sed -i \
      -e "s|^MP_DOMAIN=.*$|MP_DOMAIN=${MP_DOMAIN}|g" \
      -e "s|^MP_FQDN_POSTFIXADMIN=.*$|MP_FQDN_POSTFIXADMIN=${MP_FQDN_POSTFIXADMIN}|g" \
      -e "s|^MP_PMA_DB_HOST=.*$|MP_PMA_DB_HOST=${DB_HOST}|g" \
      -e "s|^POSTFIXADMIN_DB_HOST=.*$|POSTFIXADMIN_DB_HOST=${DB_HOST}|g" \
      -e "s|^POSTFIXADMIN_DB_PASSWORD=.*$|POSTFIXADMIN_DB_PASSWORD=${POSTFIXADMIN#*=}|g" \
      -e "s|^POSTFIXADMIN_SMTP_SERVER=.*$|POSTFIXADMIN_SMTP_SERVER=${PA_SMTP_SERVER}|g" \
      -e "s|^POSTFIXADMIN_SMTP_CLIENT=.*$|POSTFIXADMIN_SMTP_CLIENT=${PA_SMTP_CLIENT}|g" \
      -e "s|^ROUNDCUBEMAIL_DB_HOST=.*$|ROUNDCUBEMAIL_DB_HOST=${DB_HOST}|g" \
      -e "s|^ROUNDCUBEMAIL_DB_PASSWORD=.*$|ROUNDCUBEMAIL_DB_PASSWORD=${ROUNDCUBE#*=}|g" \
      -e "s|^ROUNDCUBEMAIL_DEFAULT_HOST=.*$|ROUNDCUBEMAIL_DEFAULT_HOST=ssl://${FQDN_MAIL}|g" \
      -e "s|^ROUNDCUBEMAIL_SMTP_SERVER=.*$|ROUNDCUBEMAIL_SMTP_SERVER=tls://${FQDN_SMTP}|g" \
      "${APP_DIR}/.env"
  )

  #       -e "s|^POSTFIXADMIN_SMTP_SERVER=.*$|POSTFIXADMIN_SMTP_SERVER=tls://${FQDN_SMTP}|g" \
#       -e "s|^ROUNDCUBEMAIL_SMTP_SERVER=.*$|ROUNDCUBEMAIL_SMTP_SERVER=tls://${FQDN_SMTP}|g" \


  process_web_nginx "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
}


function process_web_nginx {
  local config_file="${1}"
  local apps_dir="${2}"
  local data_dir="${3}"

  local app_dir="${apps_dir}/web"
  local service_dir="${app_dir}/nginx"

  if [[ ! -f "${data_dir}/nginx/dhparam.pem" ]]; then
    openssl dhparam -out "${data_dir}/nginx/dhparam.pem" 2048
  fi

  (
    local main_domain
    local -a web_services_list
    local enabled name host fqdn

    main_domain="$(strip_star "$(extract_main "${config_file}")")"
    web_services_list=( $(web_services_list) )

    for web_service in "${web_services_list[@]}"; do
      name="${web_service}"
      enabled="$(yq r "${config_file}" "services.web_services.${web_service}.enabled")"
      if [[ "${enabled}" = "true" ]]; then
        host="$(yq r "${config_file}" "services.web_services.${web_service}.host")"
        cp "${service_dir}/rootfs/etc/nginx/sites-available/${name}.conf" "${service_dir}/rootfs/etc/nginx/templates/${name}.conf.template"
        fqdn="${host}.${main_domain}"
      else
        rm -f "${service_dir}/rootfs/etc/nginx/sites-enabled/${name}.conf"
        rm -f "${service_dir}/rootfs/etc/nginx/templates/${name}.template"
        fqdn=""
      fi

      sed -i \
        -e "s|^MP_FQDN_${web_service^^}=.*$|MP_FQDN_${web_service^^}=${fqdn}|g" \
        "${app_dir}/.env"
    done
  )
}

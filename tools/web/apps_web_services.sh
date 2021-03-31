#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_web_services {
  echo_ok "Configuring web services"
  local config_file="${1}"
  local apps_dir="${2}"
  local data_dir="${3}"
  local log_dir="${4}"
  local extra_dir="${5}"

  local app_dir="${apps_dir}/web"

  copy_template "${app_dir}"

  cp "${app_dir}/pa/config.local.template.php" "${app_dir}/pa/config.local.php"
  cp "${app_dir}/pma/config.user.inc.template.php" "${app_dir}/pma/config.user.inc.php"
  cp "${app_dir}/roundcubemail/config.inc.template.php" "${app_dir}/roundcubemail/config.inc.php"

  (
    unset TZ

    source "${app_dir}/.env"

    set_MP_DATA_DIR_variable "${app_dir}" "${data_dir}"
    set_MP_LOG_DIR_variable "${app_dir}" "${log_dir}"
    set_MP_EXTRA_DIR_variable "${app_dir}" "${extra_dir}"
    set_TZ_variable "${config_file}" "${app_dir}"

    docker run --rm -v "${log_dir}:/tmp/log" \
      mailpine-tools:latest \
      bash -ce "chown -R 82:82 /tmp/log/roundcubemail"

    MP_DOMAIN="$(get_MP_DOMAIN "${config_file}")"
    MP_FQDN_POSTFIXADMIN="$(get_MP_FQDN_x "${config_file}" "postfixadmin")"
    if [[ -z "${MP_PMA_BLOWFISH_SECRET}" ]]; then
      MP_PMA_BLOWFISH_SECRET="$(openssl rand -base64 32)"
    fi

    DB_HOST="$(get_MP_D_CONTAINER_x "${config_file}" "mariadb" "mariadb")"
    POSTFIXADMIN="$(grep 'MP_PASSWORD_POSTFIXADMIN=' "${apps_dir}/mariadb/.env")"
    ROUNDCUBE="$(grep 'MP_PASSWORD_ROUNDCUBE=' "${apps_dir}/mariadb/.env")"
    #PA_SMTP_SERVER="$(get_MP_D_CONTAINER_x "${config_file}" "mail" "mail")"
    PA_SMTP_CLIENT="$(get_MP_D_CONTAINER_x "${config_file}" "web" "pa")"
    FQDN_MAIL="$(get_MP_FQDN_x "${config_file}" "mail")"
    FQDN_SMTP="$(get_MP_FQDN_x "${config_file}" "smtp")"

    if ! docker inspect mp_mail_mail_1 &>/dev/null; then
      echo_error "Container mp_mail_mail_1 not found, can't get its IP"
      echo_error "Start mail part before web"
    fi

    MP_MAIL_HOST_ALIAS="$(docker inspect mp_mail_mail_1 | jq -r '.[] | .NetworkSettings.Networks.mp_mail_mail.IPAddress')"

    sed -i \
      -e "s|^MP_DOMAIN=.*$|MP_DOMAIN=${MP_DOMAIN}|g" \
      -e "s|^MP_FQDN_POSTFIXADMIN=.*$|MP_FQDN_POSTFIXADMIN=${MP_FQDN_POSTFIXADMIN}|g" \
      -e "s|^MP_PMA_DB_HOST=.*$|MP_PMA_DB_HOST=${DB_HOST}|g" \
      -e "s|^MP_MAIL_HOST_ALIAS=.*$|MP_MAIL_HOST_ALIAS=${MP_MAIL_HOST_ALIAS}|g" \
      -e "s|^POSTFIXADMIN_DB_HOST=.*$|POSTFIXADMIN_DB_HOST=${DB_HOST}|g" \
      -e "s|^POSTFIXADMIN_DB_PASSWORD=.*$|POSTFIXADMIN_DB_PASSWORD=${POSTFIXADMIN#*=}|g" \
      -e "s|^POSTFIXADMIN_SMTP_SERVER=.*$|POSTFIXADMIN_SMTP_SERVER=${FQDN_SMTP}|g" \
      -e "s|^POSTFIXADMIN_SMTP_CLIENT=.*$|POSTFIXADMIN_SMTP_CLIENT=${PA_SMTP_CLIENT}|g" \
      -e "s|^ROUNDCUBEMAIL_DB_HOST=.*$|ROUNDCUBEMAIL_DB_HOST=${DB_HOST}|g" \
      -e "s|^ROUNDCUBEMAIL_DB_PASSWORD=.*$|ROUNDCUBEMAIL_DB_PASSWORD=${ROUNDCUBE#*=}|g" \
      -e "s|^ROUNDCUBEMAIL_DEFAULT_HOST=.*$|ROUNDCUBEMAIL_DEFAULT_HOST=ssl://${FQDN_MAIL}|g" \
      -e "s|^ROUNDCUBEMAIL_SMTP_SERVER=.*$|ROUNDCUBEMAIL_SMTP_SERVER=tls://${FQDN_SMTP}|g" \
      "${app_dir}/.env"
  )

  process_web_nginx "${config_file}" "${apps_dir}" "${data_dir}" "${extra_dir}"

  echo_ok_verbose "Web services configuration completed successfully"
}


function process_web_nginx {
  local config_file="${1}"
  local apps_dir="${2}"
  local data_dir="${3}"
  local extra_dir="${4}"

  local app_dir="${apps_dir}/web"
  local service_dir="${app_dir}/nginx"

  if [[ ! -f "${data_dir}/nginx/dhparam.pem" ]]; then
    echo_ok "Generating dhparam.pem file (2048 bit)"
    openssl dhparam -out "${data_dir}/nginx/dhparam.pem" 2048
    echo_ok_verbose "dhparam.pem file generated successfully"
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

    local extra_conf_file
    for extra_conf_file in "${extra_dir}/nginx/"*.conf; do
      name="$(basename "${extra_conf_file}")"
      echo_ok_verbose "Adding ${name} to nginx templates"
      cp "${extra_conf_file}" "${service_dir}/rootfs/etc/nginx/templates/${name}.template"
    done
  )
}

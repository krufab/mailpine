#!/usr/bin/env bash

echo "$(get_MP_DOMAIN "${CONFIG_FILE}")"
echo "$(get_HOST_x "${CONFIG_FILE}" "mail")"
echo "$(get_HOST_x "${CONFIG_FILE}" "smtp")"
echo "$(get_HOST_x "${CONFIG_FILE}" "postfixadmin")"
echo "$(get_HOST_x "${CONFIG_FILE}" "phpmyadmin")"
echo "$(get_HOST_x "${CONFIG_FILE}" "roundcube")"
echo "$(get_HOST_x "${CONFIG_FILE}" "traefik")"

echo "$(get_MP_FQDN_x "${CONFIG_FILE}" "mail")"
echo "$(get_MP_FQDN_x "${CONFIG_FILE}" "smtp")"
echo "$(get_MP_FQDN_x "${CONFIG_FILE}" "postfixadmin")"
echo "$(get_MP_FQDN_x "${CONFIG_FILE}" "phpmyadmin")"
echo "$(get_MP_FQDN_x "${CONFIG_FILE}" "roundcube")"

echo "$(get_MP_D_PREFIX "${CONFIG_FILE}")"
echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mail")"
echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mariadb")"
echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "traefik")"
echo "$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"

echo "$(get_MP_D_NETWORK_x "${CONFIG_FILE}" "mail")"
echo "$(get_MP_D_NETWORK_x "${CONFIG_FILE}" "mariadb")"
echo "$(get_MP_D_NETWORK_x "${CONFIG_FILE}" "traefik")"
echo "$(get_MP_D_NETWORK_x "${CONFIG_FILE}" "web")"

echo "$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mail" "mail")"
echo "$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "mariadb" "mariadb")"
echo "$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "traefik" "traefik")"
echo "$(get_MP_D_CONTAINER_x "${CONFIG_FILE}" "web" "pa")"

exit 0

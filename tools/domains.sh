#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function extract_main {
  local CONFIG_FILE

  CONFIG_FILE="${1}"

  yq r -j "${CONFIG_FILE}" | jq -r -c '.domains[0].domain'
}

function extract_main_mail {
  local CONFIG_FILE
  local MAIN MAIL

  CONFIG_FILE="${1}"

  MAIN="$(strip_star "$(extract_main "${CONFIG_FILE}")")"
  MAIL="$(yq r -j "${CONFIG_FILE}" | jq -r -c '.domains[0].mail | select (.!=null)')"

  echo "${MAIL:-mail}.${MAIN}"
}

function strip_star {
  local DOMAIN

  DOMAIN="${1}"

  if [[ "${DOMAIN:0:1}" = '*' ]]; then
    DOMAIN="${DOMAIN#*.}"
  fi

  echo "${DOMAIN}"
}

function extract_domains_list() {
  local CONFIG_FILE
  local -a DOMAINS=()
  local -a DOMAINS_JSON
  local DOMAIN_JSON DOMAIN MAIL SMTP

  CONFIG_FILE="${1}"

  readarray -t DOMAINS_JSON < <(yq r -j "${CONFIG_FILE}" | jq -r -c '.domains[]')

  for DOMAIN_JSON in "${DOMAINS_JSON[@]}"; do
    DOMAIN="$(echo -n "${DOMAIN_JSON}" | jq -r -c '.domain')"
    DOMAINS+=("${DOMAIN}")
    if [[ "${DOMAIN:0:1}" != '*' ]]; then
      MAIL="$(echo -n "${DOMAIN_JSON}" | jq -r -c '.mail | select (.!=null)')"
      if [[ -n "${MAIL}" ]]; then
        DOMAINS+=("${MAIL}.${DOMAIN}")
      else
        DOMAINS+=("mail.${DOMAIN}")
      fi
      SMTP="$(echo -n "${DOMAIN_JSON}" | jq -r -c '.smtp | select (.!=null)')"
      if [[ -n "${SMTP}" ]]; then
        DOMAINS+=("${SMTP}.${DOMAIN}")
      else
        DOMAINS+=("smtp.${DOMAIN}")
      fi
    fi
  done
  echo "${DOMAINS[@]}"
}

function web_services_list() {
  local WEB_SERVICES=(
    phpmyadmin
    postfixadmin
    roundcubemail
  )

  echo "${WEB_SERVICES[@]}"
}

function extract_web_services {
  local CONFIG_FILE MAIN_DOMAIN
  local ENABLED HOST
  local -a DOMAINS=()
  local -a WEB_SERVICES_LIST

  CONFIG_FILE="${1}"
  MAIN_DOMAIN="${2}"

  if [[ "${MAIN_DOMAIN:0:1}" = '*' ]]; then
    echo ""
    return
  fi

  WEB_SERVICES_LIST=( $(web_services_list) )

  for WEB_SERVICE in "${WEB_SERVICES_LIST[@]}"; do
    ENABLED="$(yq r "${CONFIG_FILE}" "services.web_services.${WEB_SERVICE}.enabled")"
    if [[ "${ENABLED}" = "true" ]]; then
      HOST="$(yq r "${CONFIG_FILE}" "services.web_services.${WEB_SERVICE}.host")"
      DOMAINS+=("${HOST}.${MAIN_DOMAIN}")
    fi
  done
  echo "${DOMAINS[@]}"
}

function extract_mail_domains_list() {
  local CONFIG_FILE
  local -a DOMAINS=()
  local -a DOMAINS_JSON
  local DOMAIN_JSON DOMAIN MAIL SMTP

  CONFIG_FILE="${1}"

  readarray -t DOMAINS_JSON < <(yq r -j "${CONFIG_FILE}" | jq -r -c '.domains[]')

  for DOMAIN_JSON in "${DOMAINS_JSON[@]}"; do
    DOMAIN="$(echo -n "${DOMAIN_JSON}" | jq -r -c '.domain')"
    DOMAIN="$(strip_star "${DOMAIN}")"
    DOMAINS+=("${DOMAIN}")
  done
  echo "${DOMAINS[@]}"
}

function check_domain_in_certificate() {
  local THE_DOMAIN THE_DOMAINS_LIST
  local THE_DOMAIN_STAR

  THE_DOMAIN="${1}"
  THE_DOMAINS_LIST="${2}"
  # create *.example.com
  THE_DOMAIN_STAR="*.${THE_DOMAIN#*.}"

  grep -F -q -e " ${THE_DOMAIN} " <<< " ${THE_DOMAINS_LIST} " || grep -F -q -e " ${THE_DOMAIN_STAR} " <<< " ${THE_DOMAINS_LIST} "
}

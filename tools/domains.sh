#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function extract_main {
  local config_file

  config_file="${1}"

  yq r -j "${config_file}" | jq -r -c '.domains[0].domain'
}

function extract_main_mail {
  local config_file="${1}"

  local main mail

  main="$(strip_star "$(extract_main "${config_file}")")"
  mail="$(yq r -j "${config_file}" | jq -r -c '.domains[0].mail | select (.!=null)')"

  echo "${mail:-imap}.${main}"
}

function strip_star {
  local domain="${1}"

  if [[ "${domain:0:1}" = '*' ]]; then
    domain="${domain#*.}"
  fi

  echo "${domain}"
}

function extract_domains_list {
  local config_file="${1}"

  local -a domains=()
  local -a domains_json
  local domain domain_json  mail smtp

  readarray -t domains_json < <(yq r -j "${config_file}" | jq -r -c '.domains[]')

  for domain_json in "${domains_json[@]}"; do
    domain="$(echo -n "${domain_json}" | jq -r -c '.domain')"
    domains+=("${domain}")
    if [[ "${domain:0:1}" != '*' ]]; then
      mail="$(echo -n "${domain_json}" | jq -r -c '.mail | select (.!=null)')"
      if [[ -n "${mail}" ]]; then
        domains+=("${mail}.${domain}")
      else
        domains+=("imap.${domain}")
      fi
      smtp="$(echo -n "${domain_json}" | jq -r -c '.smtp | select (.!=null)')"
      if [[ -n "${smtp}" ]]; then
        domains+=("${smtp}.${domain}")
      else
        domains+=("smtp.${domain}")
      fi
    fi
  done
  echo "${domains[@]}"
}

function web_services_list {
  local -a web_services=(
    "phpmyadmin"
    "postfixadmin"
    "roundcubemail"
  )

  echo "${web_services[@]}"
}

function extract_web_services {
  local config_file="${1}"
  local main_domain="${2}"

  local enabled host web_service
  local -a domains=()
  local -a web_services_list


  if [[ "${main_domain:0:1}" = '*' ]]; then
    echo ""
    return
  fi

  web_services_list=( $(web_services_list) )

  for web_service in "${web_services_list[@]}"; do
    enabled="$(yq r "${config_file}" "services.web_services.${web_service}.enabled")"
    if [[ "${enabled}" = "true" ]]; then
      host="$(yq r "${config_file}" "services.web_services.${web_service}.host")"
      domains+=("${host}.${main_domain}")
    fi
  done
  echo "${domains[@]}"
}

function extract_extra_domains {
  local config_file="${1}"

  local -a domains=()
  readarray -t domains < <(yq r -j "${config_file}" | jq -r -c '.extra_domains[]')
  echo "${domains[@]}"
}

function extract_mail_domains_list {
  local config_file="${1}"
  local -a domains=()
  local -a domains_json
  local domain domain_json

  readarray -t domains_json < <(yq r -j "${config_file}" | jq -r -c '.domains[]')

  for domain_json in "${domains_json[@]}"; do
    domain="$(echo -n "${domain_json}" | jq -r -c '.domain')"
    domain="$(strip_star "${domain}")"
    domains+=("${domain}")
  done
  echo "${domains[@]}"
}

function check_domain_in_certificate {
  local domain="${1}"
  local domains_list="${2}"

  # creates *.example.com
  local domain_star="*.${domain#*.}"

  grep -F -q -e " ${domain} " <<< " ${domains_list} " || grep -F -q -e " ${domain_star} " <<< " ${domains_list} "
}

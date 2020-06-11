#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function manage_opendmarc() {
  local CONFIG_FILE
  local -a DOMAINS
  local -i RESULT

  CONFIG_FILE="${1}"

  MAIL_MAIN="$(extract_main_mail "${CONFIG_FILE}")"
  MAIL_A="$(dig +short A "${MAIL_MAIN}")"

  DOMAINS=( $(extract_mail_domains_list "${CONFIG_FILE}") )

  for DOMAIN in "${DOMAINS[@]}"; do
    if docker run --rm \
      mailpine-tools:latest \
      bash -ce " \
        opendmarc-check "${DOMAIN}" > /dev/null 2>&1
      "; then
        echo_ok "DMARC record for ${DOMAIN} is correct"
      else
        echo_error "Missing or incorrect DMARC record for: ${DOMAIN}"
        echo_info "Set TXT record for ${DOMAIN}: '_dmarc. IN TXT \"v=DMARC1; p=quarantine; pct=20; adkim=s; aspf=r; fo=1; rua=mailto:postmaster@${DOMAIN}; ruf=mailto:forensic@${DOMAIN};\""
      fi
  done
}

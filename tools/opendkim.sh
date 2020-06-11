#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function generate_opendkim() {
  local DOMAIN OPENDKIM_DIR
  local SELECTOR='mail' COMMAND_PARAMS
  local LOCAL_PUBLIC DNS_PUBLIC

  DOMAIN="${1}"
  OPENDKIM_DIR="${2}"

  local DOMAIN_DIR="${OPENDKIM_DIR}/keys/${DOMAIN}"
  local PRIVATE_FILE="${DOMAIN_DIR}/${SELECTOR}.private"
  local TXT_FILE="${DOMAIN_DIR}/${SELECTOR}.txt"

  local CHROOT_BASE_DIR="/data/opendkim"
  local CHROOT_DIR="${CHROOT_BASE_DIR}/keys/${DOMAIN}"
  local CHROOT_PRIVATE_FILE="${CHROOT_DIR}/${SELECTOR}.private"

  if [[ ! -f "${PRIVATE_FILE}" ]]; then
    mkdir -p "${DOMAIN_DIR}";

    COMMAND_PARAMS="$(cat <<EOF
opendkim-genkey \
  --directory="${CHROOT_DIR}" \
  --domain="${DOMAIN}" \
  --selector="${SELECTOR}" \
  --append-domain
EOF
    )"

    docker run --rm \
      -u 1000:1000 \
      -v "${OPENDKIM_DIR}:${CHROOT_BASE_DIR}" \
      mailpine-tools:latest \
      bash -ce "${COMMAND_PARAMS}"
  fi

  echo "${SELECTOR}._domainkey.${DOMAIN} ${DOMAIN}:${SELECTOR}:${CHROOT_PRIVATE_FILE}" >> "${OPENDKIM_DIR}/KeyTable"
  echo "*@${DOMAIN} ${SELECTOR}._domainkey.${DOMAIN}" >> "${OPENDKIM_DIR}/SigningTable"

  sed -i -E '$!N;s/"\n[[:space:]]+"//;P;D' "${TXT_FILE}"
  LOCAL_PUBLIC=$(grep -o -E '".+"' "${TXT_FILE}")
  DNS_PUBLIC="$(dig -t TXT "${SELECTOR}._domainkey.${DOMAIN}" +short)"
  if [[ "${LOCAL_PUBLIC}" != "${DNS_PUBLIC}" ]]; then
    echo_error "Public TXT record not correct for ${SELECTOR}._domainkey.${DOMAIN}"
    cat "${TXT_FILE}"
  else
    echo_ok "Public TXT record ok ${SELECTOR}._domainkey.${DOMAIN}"
  fi
}

function manage_opendkim() {
  local CONFIG_FILE OPENDKIM_DIR
  local CHROOT_BASE_DIR SELECTOR='mail'
  local DOMAIN_DIR PRIVATE_FILE TXT_FILE CHROOT_DIR
  local -a DOMAINS

  CONFIG_FILE="${1}"
  OPENDKIM_DIR="${2}"

  CHROOT_BASE_DIR="/data/opendkim"

  DOMAINS=( $(extract_mail_domains_list "${CONFIG_FILE}") )

  USER_ID="$(id -u):$(id -g)"
  docker run --rm \
    -v "${OPENDKIM_DIR}:${CHROOT_BASE_DIR}" \
    mailpine-tools:latest \
    bash -ce " \
      chown -R ${USER_ID} ${CHROOT_BASE_DIR}
    "

  docker run --rm \
    -v "${OPENDKIM_DIR}:${CHROOT_BASE_DIR}" \
    mailpine-tools:latest \
    bash -ce " \
      true > "${CHROOT_BASE_DIR}/KeyTable"; \
      true > "${CHROOT_BASE_DIR}/SigningTable" \
    "

#  true > "${OPENDKIM_DIR}/KeyTable"
#  true > "${OPENDKIM_DIR}/SigningTable"

  for DOMAIN in "${DOMAINS[@]}"; do
    generate_opendkim "${DOMAIN}" "${OPENDKIM_DIR}"
  done
}

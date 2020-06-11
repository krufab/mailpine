#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function get_container_network_or_die() {
  local PORT
  local CONTAINER_NETWORK

  PORT="${1}"

  CONTAINER_NETWORK="$(docker container ls --filter "publish=${PORT}" --format "{{.Networks}}")"
  if [[ -z "${CONTAINER_NETWORK}" ]]; then
    echo_error "Could not find container listening on port 80"
    exit 1
  fi

  echo "${CONTAINER_NETWORK}"
}

function generate_certificate() {
  local CONFIG_FILE DATA_DIR MAIN_DOMAIN_NO_STAR
  local -a ALL_DOMAINS LIST_DOMAINS
  local DNS_CHALLENGE DOCKER_PARAMS TRAEFIK_NETWORK

  CONFIG_FILE="${1}"
  shift
  DATA_DIR="${1}"
  shift
  MAIN_DOMAIN_NO_STAR="${1}"
  shift
  ALL_DOMAINS=( ${@} )

  local ACME_DIR="${DATA_DIR}/acme.sh"
  local CERTS_DIR="${DATA_DIR}/certs"

  DNS_CHALLENGE="$(yq r "${CONFIG_FILE}" "config[acme.sh].default_dns_challenge")"
  #FORCE="$(yq r "${CONFIG_FILE}" "config[acme.sh].force")"
  echo_info "DNS challenge: '${DNS_CHALLENGE}'"

  if [[ "${DNS_CHALLENGE}" = "" ]] && grep -q -F -e '*' <<< " ${ALL_DOMAINS[*]} "; then
    echo "${ALL_DOMAINS[*]}"
    echo_error "Error: *.domains require a dns challenge"
    exit 1
  fi

  LIST_DOMAINS=("-d ${MAIN_DOMAIN_NO_STAR}")
  for DOMAIN in "${ALL_DOMAINS[@]}"; do
    LIST_DOMAINS+=("-d ${DOMAIN}")
  done

  if ! nc -z localhost 80 &>/dev/null; then
    # No traefik
    DOCKER_PARAMS="$(cat <<EOF
--rm -it --net=host \
  -v ${ACME_DIR}:/acme.sh \
  -v ${CERTS_DIR}:/certs
EOF
    )"
  else
    # Look for traefik container's network
    TRAEFIK_NETWORK="$(get_container_network_or_die "80")"
    # Traefik
    DOCKER_PARAMS="$(cat <<EOF
--rm -it --net=${TRAEFIK_NETWORK} \
  -v ${ACME_DIR}:/acme.sh \
  -v ${CERTS_DIR}:/certs  \
  -l traefik.enable=true \
  -l traefik.docker.network=${TRAEFIK_NETWORK} \
  -l traefik.http.routers.le.entrypoints=web,websecure \
  -l traefik.http.routers.le.rule=PathPrefix(\`/.well-known/acme-challenge/\`) \
  -l traefik.http.routers.le.priority=10 \
  -l traefik.http.routers.le.service=le \
  -l traefik.http.services.le.loadbalancer.server.port=80
EOF
    )"
  fi

  SH_PARAMS=$(cat <<EOF
acme.sh --cert-home /certs --issue --test --standalone ${LIST_DOMAINS[@]} ${DNS_CHALLENGE}
EOF
    )

  if ! docker run ${DOCKER_PARAMS} neilpang/acme.sh:latest sh -c "${SH_PARAMS}"; then
    echo "Run it again"
    exit 1
  else
    echo_ok "Certificate created successfully"
    ln -s -f "${MAIN_DOMAIN_NO_STAR}/fullchain.cer" "${CERTS_DIR}/fullchain.cer"
    ln -s -f "${MAIN_DOMAIN_NO_STAR}/${MAIN_DOMAIN_NO_STAR}.key" "${CERTS_DIR}/server.key"
  fi
}

function check_certificate() {
  local CERTS_DIR
  local -a ALL_DOMAINS
  local CERT_FILE SAN SHOULD_GENERATE_CERTIFICATE
  local -i EXPIRE_DAYS=15 FOUND_ALL
  local -i EXPIRE_DAYS_IN_SEC=$(( 3600*24*EXPIRE_DAYS ))

  CERTS_DIR="${1}"
  shift
  ALL_DOMAINS=( ${@} )

  CERT_FILE="${CERTS_DIR}/fullchain.cer"
#  CERT_FILE="${CERTS_DIR}/expired/server-fullchain.pem"
#  CERT_FILE="${CERTS_DIR}/non-existent.cer"

  SHOULD_GENERATE_CERTIFICATE='false'
  if [[ -f "${CERT_FILE}" ]]; then
    if openssl x509 -checkend "${EXPIRE_DAYS_IN_SEC}" -noout -in "${CERT_FILE}" > /dev/null; then
      echo_ok "Certificate will not expire soon"

      SAN="$(docker run --rm -v \
        "${CERTS_DIR}:/tmp" mailpine-tools:latest bash -ce "
          openssl x509 -noout -ext subjectAltName \
            -in "/tmp/fullchain.cer" \
          | grep "DNS:" | sed -E -e 's/^\s+|DNS:|,|\s+$//g'
      ")"

      echo_info "SAN: ${SAN}"

      FOUND_ALL=1
      for DOMAIN in "${ALL_DOMAINS[@]}"; do
        if ! check_domain_in_certificate "${DOMAIN}" "${SAN}"; then
          echo_error "Missing domain in certificate: '${DOMAIN}'"
          FOUND_ALL=0
        fi
      done

      if [[ FOUND_ALL -eq 0 ]]; then
        echo_error "The certificate does not contain all domains"
        SHOULD_GENERATE_CERTIFICATE='true'
      fi

    else
      echo_error "Certificate expired or will expire in less than ${EXPIRE_DAYS} days"
      SHOULD_GENERATE_CERTIFICATE='true'
    fi
  else
    echo_error "Certificate file '${CERT_FILE}' does not exist"
    SHOULD_GENERATE_CERTIFICATE='true'
  fi

  if [[ "${SHOULD_GENERATE_CERTIFICATE}" = 'true' ]]; then
    return 1
  else
    return 0
  fi
}

function manage_certificates() {
  local CONFIG_FILE DATA_DIR
  local CERTS_DIR
  local MAIN_DOMAIN MAIN_DOMAIN_NO_STAR
  local -a DOMAINS WEB_SERVICES ALL_DOMAINS

  CONFIG_FILE="${1}"
  DATA_DIR="${2}"

  CERTS_DIR="${DATA_DIR}/certs"

  MAIN_DOMAIN="$(extract_main "${CONFIG_FILE}")"
  MAIN_DOMAIN_NO_STAR="$(strip_star "${MAIN_DOMAIN}")"
  DOMAINS=( $(extract_domains_list "${CONFIG_FILE}") )
  WEB_SERVICES=( $(extract_web_services "${CONFIG_FILE}" "${MAIN_DOMAIN}") )
  ALL_DOMAINS=("${DOMAINS[@]}" "${WEB_SERVICES[@]}")

  echo_info "Main domain: '${MAIN_DOMAIN}'"
  echo_info "Main domain (no star): '${MAIN_DOMAIN_NO_STAR}'"
  echo_info "All domains: '${ALL_DOMAINS[*]}'"

  if ! check_certificate "${CERTS_DIR}" "${ALL_DOMAINS[@]}"; then
    echo_info "Not all domains found → Requesting new certificate"
    generate_certificate "${CONFIG_FILE}" "${DATA_DIR}" "${MAIN_DOMAIN_NO_STAR}" "${ALL_DOMAINS[@]}"
  else
    echo_ok "Certificate contains all domains"
  fi
}

export -f manage_certificates

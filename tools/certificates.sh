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
  local CONFIG_FILE="${1}"
  shift
  local DATA_DIR="${1}"
  shift
  local KEY_TYPE="${1}"
  shift
  local MAIN_DOMAIN_NO_STAR="${1}"
  shift

  local -a ALL_DOMAINS=( ${@} )
  local -a LIST_DOMAINS
  local IS_STAGING_CA DNS_CHALLENGE DOCKER_PARAMS

  local ACME_DIR="${DATA_DIR}/acme.sh"
  local CERTS_DIR="${DATA_DIR}/certs"
  local ACME_CA=""
  local KEY_LENGTH KEY_TYPE_FOLDER

  if [[ "${KEY_TYPE}" == "-" ]]; then
    KEY_LENGTH="$(yq r "${CONFIG_FILE}" "config[acme.sh].keylength")"
    KEY_TYPE=""
    KEY_TYPE_FOLDER=""
  else
    KEY_LENGTH="$(yq r "${CONFIG_FILE}" "config[acme.sh].keylength-ec")"
    KEY_TYPE_FOLDER="_ecc"
  fi

  IS_STAGING_CA="$(yq r "${CONFIG_FILE}" "config[acme.sh].staging")"
  if [[ "${IS_STAGING_CA}" == "true" ]]; then
    ACME_CA="--test"
  fi
  DNS_CHALLENGE="$(yq r "${CONFIG_FILE}" "config[acme.sh].default_dns_challenge")"

  FORCE="$(yq r "${CONFIG_FILE}" "config[acme.sh].force")"
  if [[ ${FORCE} == "true" ]]; then
    FORCE="--force"
  else
    FORCE=""
  fi
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

  declare ACME_SH_NETWORK

  if ! nc -z localhost 80 &>/dev/null; then
    # No nginx
    echo_info_verbose "Port 80 free"
    ACME_SH_NETWORK="host"
  else
    echo_info_verbose "Port 80 in use, using nginx"
    # Look for nginx container's network
    ACME_SH_NETWORK="$(get_container_network_or_die "80")"
  fi

  DOCKER_PARAMS="$(cat <<EOF
--rm --name mp_acme_sh --net=${ACME_SH_NETWORK} \
  -v ${ACME_DIR}:/acme.sh \
  -v ${CERTS_DIR}:/certs
EOF
  )"

  SH_PARAMS="$(cat <<EOF
acme.sh --cert-home /certs --issue ${ACME_CA} --ecc --keylength ${KEY_LENGTH} --accountkeylength 4096 --standalone ${LIST_DOMAINS[@]} ${DNS_CHALLENGE} ${FORCE}
EOF
    )"

    #--ocsp-must-staple

  if ! docker run ${DOCKER_PARAMS} neilpang/acme.sh:latest sh -c "${SH_PARAMS}"; then
    echo "Run it again"
    exit 1
  else
    echo_ok "Certificate created successfully"
    ln -s -f "${MAIN_DOMAIN_NO_STAR}${KEY_TYPE_FOLDER}/fullchain.cer" "${CERTS_DIR}/${KEY_TYPE}fullchain.cer"
    ln -s -f "${MAIN_DOMAIN_NO_STAR}${KEY_TYPE_FOLDER}/${MAIN_DOMAIN_NO_STAR}.key" "${CERTS_DIR}/${KEY_TYPE}server.key"
  fi

  if [[ ! -f "${CERTS_DIR}/ca.cer" ]]; then
    ln -s -f "${MAIN_DOMAIN_NO_STAR}${KEY_TYPE_FOLDER}/ca.cer" "${CERTS_DIR}/ca.cer"
  fi
}

function check_certificate() {
  local CERTS_DIR="${1}"
  shift
  local KEY_TYPE="${1}"
  shift
  local -a ALL_DOMAINS=( ${@} )

  local CERT_FILE SAN SHOULD_GENERATE_CERTIFICATE
  local -i EXPIRE_DAYS=15 FOUND_ALL
  local -i EXPIRE_DAYS_IN_SEC=$(( 3600*24*EXPIRE_DAYS ))

  if [[ "${KEY_TYPE}" == "-" ]]; then
    KEY_TYPE=""
  fi

  CERT_FILE="${CERTS_DIR}/${KEY_TYPE}fullchain.cer"
  echo_ok_verbose "Certificate: ${CERT_FILE}"

  SHOULD_GENERATE_CERTIFICATE='false'
  if [[ -f "${CERT_FILE}" ]]; then
    if openssl x509 -checkend "${EXPIRE_DAYS_IN_SEC}" -noout -in "${CERT_FILE}" > /dev/null; then
      echo_ok "Certificate will not expire soon"

      SAN="$(docker run --rm -v \
        "${CERTS_DIR}:/tmp" mailpine-tools:latest bash -ce "
          openssl x509 -noout -ext subjectAltName \
            -in "/tmp/${KEY_TYPE}fullchain.cer" \
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

function configure_certificates() {
  echo_ok "Checking certificates"

  local CONFIG_FILE DATA_DIR
  local CERTS_DIR
  local MAIN_DOMAIN MAIN_DOMAIN_NO_STAR
  local -a DOMAINS WEB_SERVICES ALL_DOMAINS

  CONFIG_FILE="${1}"
  DATA_DIR="${2}"

  CERTS_DIR="${DATA_DIR}/certs"
  CERTS_EC_DIR="${DATA_DIR}/certs-ec"

  MAIN_DOMAIN="$(extract_main "${CONFIG_FILE}")"
  MAIN_DOMAIN_NO_STAR="$(strip_star "${MAIN_DOMAIN}")"
  DOMAINS=( $(extract_domains_list "${CONFIG_FILE}") )
  WEB_SERVICES=( $(extract_web_services "${CONFIG_FILE}" "${MAIN_DOMAIN}") )
  ALL_DOMAINS=("${DOMAINS[@]}" "${WEB_SERVICES[@]}")

  echo_info "Main domain: '${MAIN_DOMAIN}'"
  echo_info "Main domain (no star): '${MAIN_DOMAIN_NO_STAR}'"
  echo_info "All domains: '${ALL_DOMAINS[*]}'"

  for KEY_TYPE in "-" "ecc_"; do
    if ! check_certificate "${CERTS_DIR}" "${KEY_TYPE}" "${ALL_DOMAINS[@]}"; then
      echo_info "Not all domains found → Requesting new certificate"
      generate_certificate "${CONFIG_FILE}" "${DATA_DIR}" "${KEY_TYPE}" "${MAIN_DOMAIN_NO_STAR}" "${ALL_DOMAINS[@]}"
  #  else
  #    echo_ok_verbose "Certificate contains all domains"
    fi
  done

  echo_ok_verbose "Certificates check completed successfully"
}

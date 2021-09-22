#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function get_container_network_or_die {
  local port="${1}"
  local container_network

  container_network="$(docker container ls --filter "publish=${port}" --format "{{.Networks}}")"
  if [[ -z "${container_network}" ]]; then
    echo_error "Could not find container listening on port 80"
    exit 1
  fi

  echo "${container_network}"
}

function generate_certificate {
  local config_file="${1}"
  shift
  local data_dir="${1}"
  shift
  local key_type="${1}"
  shift
  local main_domain_no_star="${1}"
  shift

  local -a all_domains=( ${@} )
  local -a list_domains
  local acme_sh_network dns_challenge docker_params domain force is_staging_ca is_debug sh_params

  local acme_dir="${data_dir}/acme.sh"
  local certs_dir="${data_dir}/certs"
  local acme_ca=""
  local key_length key_type_folder
  local debug=""

  if [[ "${key_type}" == "-" ]]; then
    key_length="$(yq r "${config_file}" "config[acme.sh].keylength")"
    key_type=""
    key_type_folder=""
  else
    key_length="$(yq r "${config_file}" "config[acme.sh].keylength-ec")"
    key_type_folder="_ecc"
  fi

  is_debug="$(yq r "${config_file}" "config[acme.sh].debug")"
  if [[ "${is_debug}" == "true" ]]; then
    debug="--debug"
  fi

  is_staging_ca="$(yq r "${config_file}" "config[acme.sh].staging")"
  if [[ "${is_staging_ca}" == "true" ]]; then
    acme_ca="--test"
  fi
  dns_challenge="$(yq r "${config_file}" "config[acme.sh].default_dns_challenge")"

  force="$(yq r "${config_file}" "config[acme.sh].force")"
  if [[ "${force}" == "true" ]]; then
    force="--force"
  else
    force=""
  fi
  echo_info "DNS challenge: '${dns_challenge}'"

  if [[ "${dns_challenge}" = "" ]] && grep -q -F -e '*' <<< " ${all_domains[*]} "; then
    echo "${all_domains[*]}"
    echo_error "Error: *.domains require a dns challenge"
    exit 1
  fi

  list_domains=("-d ${main_domain_no_star}")
  for domain in "${all_domains[@]}"; do
    list_domains+=("-d ${domain}")
  done

  if ! nc -z localhost 80 &>/dev/null; then
    # No nginx
    echo_info_verbose "Port 80 free"
    acme_sh_network="host"
  else
    echo_info_verbose "Port 80 in use, using nginx"
    # Look for nginx container's network
    acme_sh_network="$(get_container_network_or_die "80")"
  fi

  docker_params="$(cat <<EOF
--rm --name mp_acme_sh --net=${acme_sh_network} \
  -v ${acme_dir}:/acme.sh \
  -v ${certs_dir}:/certs
EOF
  )"

  sh_params="$(cat <<EOF
acme.sh ${debug} --cert-home /certs \
  --issue ${acme_ca} \
  --ecc --keylength ${key_length} \
  --accountkeylength 4096 \
  --standalone \
  ${list_domains[@]} \
  ${dns_challenge} \
  ${force}
EOF
  )"

    #--ocsp-must-staple

  # shellcheck disable=SC2086
  if ! docker run ${docker_params} neilpang/acme.sh:latest sh -c "${sh_params}"; then
    echo_error "Run it again"
    exit 1
  else
    echo_ok "Certificate created successfully"
    ln -s -f "${main_domain_no_star}${key_type_folder}/fullchain.cer" "${certs_dir}/${key_type}fullchain.cer"
    ln -s -f "${main_domain_no_star}${key_type_folder}/${main_domain_no_star}.key" "${certs_dir}/${key_type}server.key"
  fi

  if [[ ! -f "${certs_dir}/ca.cer" ]]; then
    ln -s -f "${main_domain_no_star}${key_type_folder}/ca.cer" "${certs_dir}/ca.cer"
  fi
}

function check_certificate {
  local certs_dir="${1}"
  shift
  local key_type="${1}"
  shift
  local -a all_domains=( ${@} )

  local cert_file="${certs_dir}/${key_type}fullchain.cer"
  local found_all san should_generate_certificate
  local -i expire_days=15
  local -i expire_days_in_sec=$(( 3600*24*expire_days ))

  if [[ "${key_type}" == "-" ]]; then
    key_type=""
  fi

  cert_file="${certs_dir}/${key_type}fullchain.cer"
  echo_ok_verbose "Certificate: ${cert_file}"

  should_generate_certificate='false'
  if [[ -f "${cert_file}" ]]; then
    if openssl x509 -checkend "${expire_days_in_sec}" -noout -in "${cert_file}" > /dev/null; then
      echo_ok "Certificate will not expire soon"

      san="$(docker run --rm -v \
        "${certs_dir}:/tmp" mailpine-tools:latest bash -ce "
          openssl x509 -noout -ext subjectAltName \
            -in \"/tmp/${key_type}fullchain.cer\" \
          | grep \"DNS:\" | sed -E -e 's/^\s+|DNS:|,|\s+$//g'
      ")"

      echo_info "SAN: ${san}"

      found_all="true"
      for domain in "${all_domains[@]}"; do
        if ! check_domain_in_certificate "${domain}" "${san}"; then
          echo_error "Missing domain in certificate: '${domain}'"
          found_all="false"
        fi
      done

      if [[ "${found_all}" == "false" ]]; then
        echo_error "The certificate does not contain all domains"
        should_generate_certificate='true'
      fi

    else
      echo_error "Certificate expired or will expire in less than ${expire_days} days"
      should_generate_certificate='true'
    fi
  else
    echo_error "Certificate file '${cert_file}' does not exist"
    should_generate_certificate='true'
  fi

  if [[ "${should_generate_certificate}" = 'true' ]]; then
    return 1
  else
    return 0
  fi
}

function configure_certificates {
  echo_ok "Checking certificates"
  local config_file="${1}"
  local data_dir="${2}"

  local certs_dir="${data_dir}/certs"

  local key_type main_domain main_domain_no_star
  local -a all_domains domains extra_domains web_services

  main_domain="$(extract_main "${config_file}")"
  main_domain_no_star="$(strip_star "${main_domain}")"
  domains=( $(extract_domains_list "${config_file}") )
  web_services=( $(extract_web_services "${config_file}" "${main_domain}") )
  extra_domains=( $(extract_extra_domains "${config_file}") )
  all_domains=("${domains[@]}" "${web_services[@]}" "${extra_domains[@]}")

  echo_info "Main domain: '${main_domain}'"
  echo_info "Main domain (no star): '${main_domain_no_star}'"
  echo_info "All domains: '${all_domains[*]}'"

  for key_type in "-" "ecc_"; do
    if ! check_certificate "${certs_dir}" "${key_type}" "${all_domains[@]}"; then
      echo_info "Not all domains found → Requesting new certificate"
      generate_certificate "${config_file}" "${data_dir}" "${key_type}" "${main_domain_no_star}" "${all_domains[@]}"
  #  else
  #    echo_ok_verbose "Certificate contains all domains"
    fi
  done

  echo_ok_verbose "Certificates check completed successfully"
}

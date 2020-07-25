#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

#dig -t A $(dig -t MX fabio.is +short | cut -d' ' -f2 | sed -e 's|.$||') +short

#spfquery --scope mfrom --identity fabio.is --ip-address 51.15.79.253 --helo-identity mail.fabio.is

function configure_spf {
  echo_ok "Checking spf settings"
  local CONFIG_FILE
  local -a DOMAINS
  local -i RESULT

  CONFIG_FILE="${1}"

  MAIL_MAIN="$(extract_main_mail "${CONFIG_FILE}")"
  MAIL_A="$(dig +short A "${MAIL_MAIN}")"

  DOMAINS=( $(extract_mail_domains_list "${CONFIG_FILE}") )

  for DOMAIN in "${DOMAINS[@]}"; do
    MX="$(dig -t MX "${DOMAIN}" +short @1.1.1.1 | cut -d' ' -f2)"
    MAIL_HOST="$(sed -e 's|.$||' <<< "${MX}")"

    A="$(dig -t A +short "${MAIL_HOST}" @1.1.1.1)"
    PTR="$(dig +short -x "${A}" @1.1.1.1)"
    #echo "${MX} - ${MAIL_HOST}  - ${A} - ${PTR}"

    if [[ "${MX}" != "${PTR}" ]]; then
      echo_error "${MX} != ${PTR}"
      echo_info "Set MX record for ${DOMAIN} to ${PTR}"
    else
      :
      #echo_ok "MX = PTR (${MX} = ${PTR})"
    fi

    set +e
    docker run --rm \
      mailpine-tools:latest \
      bash -ce " \
        spfquery -sender="${DOMAIN}" -ip="${A}" -helo="${MAIL_HOST}" > /dev/null #2>&1
      "
    RESULT=$?
    set -e
    if [[ ${RESULT} -ne 2 ]]; then
      echo_error "Not valid spf"
      echo_info "Set TXT record for ${DOMAIN}: '${DOMAIN}. IN TXT \"v=spf1 mx a ip:${MAIL_A} -all\"'"
    else
      echo_ok "Valid spf"
    fi

#      spfquery --scope helo --identity "${DOMAIN}" --ip-address "${A}" --helo-identity "${MAIL_HOST}" #&>/dev/null
#      spfquery --scope mfrom --identity "${DOMAIN}" --ip-address "${A}" --helo-identity "${MAIL_HOST}" #&>/dev/null

# "v=spf1 mx a ip4:51.15.79.253 -all"

# https://github.com/shevek/libspf2/blob/master/src/include/spf_response.h
#	SPF_RESULT_INVALID = 0,		/**< We should never return this. */
#	SPF_RESULT_NEUTRAL,
#	SPF_RESULT_PASS,
#	SPF_RESULT_FAIL,
#	SPF_RESULT_SOFTFAIL,
#
#	SPF_RESULT_NONE,
#	SPF_RESULT_TEMPERROR,
#	SPF_RESULT_PERMERROR
#
  done
  echo_ok_verbose "Spf check settings completed successfully"
}

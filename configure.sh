#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

if ! command -v yq &>/dev/null; then
  echo "You need to have yq installed"
  echo "Check https://github.com/mikefarah/yq"
  exit 1
fi

if ! readlink --help | grep -q -- '-f, --canonicalize'; then
  echo "Your system doesn't support 'readlink -f'"
  echo "You need to have coreutils installed and in the path"
  echo "Check https://stackoverflow.com/a/4031502/8989626"
  exit 1
fi

if ! command -v nc &>/dev/null; then
  echo "You need to have nc installed"
  echo "Install it according to your OS"
  exit 1
fi

if ! sed --help | grep -q -- '--follow-symlinks'; then
  echo "Your system doesn't support 'sed --follow-symlinks'"
  echo "You need to have GNU sed installed and in the path"
  echo "Install it according to your OS"
  echo "On mac: brew install gnu-sed"
  exit 1
fi

declare THIS_PATH
declare CONFIG_FILE
declare APPS_DIR
declare DATA_DIR
declare -a DATA_SUBDIRS

THIS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/domains.sh
source "${THIS_PATH}/tools/domains.sh"
# shellcheck source=./tools/certificates.sh
source "${THIS_PATH}/tools/certificates.sh"
# shellcheck source=./tools/opendkim.sh
source "${THIS_PATH}/tools/opendkim.sh"
# shellcheck source=./tools/apps_mail.sh
source "${THIS_PATH}/tools/apps_mail.sh"
# shellcheck source=./tools/apps_mariadb.sh
source "${THIS_PATH}/tools/apps_mariadb.sh"
# shellcheck source=./tools/apps_traefik.sh
source "${THIS_PATH}/tools/apps_traefik.sh"
# shellcheck source=./tools/apps_web_services.sh
source "${THIS_PATH}/tools/apps_web_services.sh"
# shellcheck source=./tools/spf.sh
source "${THIS_PATH}/tools/spf.sh"
# shellcheck source=./tools/opendmarc.sh
source "${THIS_PATH}/tools/opendmarc.sh"
# shellcheck source=./tools/names.sh
source "${THIS_PATH}/tools/names.sh"
# shellcheck source=./tools/docker.sh
source "${THIS_PATH}/tools/docker.sh"

CONFIG_FILE="${THIS_PATH}/config.yml"

APPS_DIR="${THIS_PATH}/apps"
DATA_DIR="$(realpath "$(yq r "${CONFIG_FILE}" 'config.data-dir')")"
DATA_SUBDIRS=(
'acme.sh'
'certs'
'letsencrypt'
'mail'
'mail/postfix'
'opendkim'
'opendmarc'
'unbound'
)

check_or_create_dir_or_exit "${DATA_DIR}"
for SUBDIR in "${DATA_SUBDIRS[@]}"; do
  check_or_create_dir_or_exit "${DATA_DIR}/${SUBDIR}"
done

check_mailpine_tools
echo_ok "Docker image available"

manage_certificates "${CONFIG_FILE}" "${DATA_DIR}"
echo_ok "Certificate check completed successfully"

manage_opendkim "${CONFIG_FILE}" "${DATA_DIR}/opendkim"
echo_ok "Opendkim check completed successfully"

manage_opendmarc "${CONFIG_FILE}"
echo_ok "Opendmarc check completed successfully"

manage_spf "${CONFIG_FILE}"
echo_ok "SPF check completed successfully"

process_traefik "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
process_mariadb "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
process_mail "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"
process_web_services "${CONFIG_FILE}" "${APPS_DIR}" "${DATA_DIR}"

echo_ok "Configuration completed successfully"

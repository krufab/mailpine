#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function prepare_folders() {
  echo_ok "Setting up folder structure"

  local DATA_DIR="${1}"
  local LOGS_DIR="${2}"

  local -a DATA_SUBDIRS=(
    'acme.sh'
    'certs'
    'letsencrypt'
    'mail'
    'mail/postfix'
    'opendkim'
    'opendmarc'
    'roundcubemail'
    'unbound'
  )

  check_or_create_dir_or_exit "${DATA_DIR}"
  for SUBDIR in "${DATA_SUBDIRS[@]}"; do
    check_or_create_dir_or_exit "${DATA_DIR}/${SUBDIR}"
    check_or_create_dir_or_exit "${LOGS_DIR}/${SUBDIR}"
  done

  echo_ok_verbose "Folder structure created successfully"
}
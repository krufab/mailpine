#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function prepare_folders {
  echo_ok "Setting up folder structure"

  local DATA_DIR="${1}"
  local LOG_DIR="${2}"

  local -a DATA_SUBDIRS=(
    'acme.sh'
    'certs'
    'letsencrypt'
    'mail'
    'mail/postfix'
    'nginx'
    'opendkim'
    'opendmarc'
    'roundcubemail'
    'unbound'
  )

  local -a LOG_SUBDIRS=(
    'mail'
    'nginx'
  )

  check_or_create_dir_or_exit "${DATA_DIR}"
  for SUBDIR in "${DATA_SUBDIRS[@]}"; do
    check_or_create_dir_or_exit "${DATA_DIR}/${SUBDIR}"
  done

  check_or_create_dir_or_exit "${LOG_DIR}"
  for SUBDIR in "${LOG_SUBDIRS[@]}"; do
    check_or_create_dir_or_exit "${LOG_DIR}/${SUBDIR}"
  done

  echo_ok_verbose "Folder structure created successfully"
}
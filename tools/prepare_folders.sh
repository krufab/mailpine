#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function prepare_folders {
  echo_ok "Setting up folder structure"

  local data_dir="${1}"
  local log_dir="${2}"

  local -a data_subdirs=(
    'acme.sh'
    'antivirus'
    'certs'
    'fail2ban'
    'letsencrypt'
    'mail'
    'mail/postfix'
    'nginx'
    'opendkim'
    'opendmarc'
    'roundcubemail'
    'unbound'
  )

  local -a log_subdirs=(
    'antivirus'
    'mail'
    'nginx'
    'roundcubemail'
  )

  check_or_create_dir_or_exit "${data_dir}"
  for SUBDIR in "${data_subdirs[@]}"; do
    check_or_create_dir_or_exit "${data_dir}/${SUBDIR}"
  done

  check_or_create_dir_or_exit "${log_dir}"
  for SUBDIR in "${log_subdirs[@]}"; do
    check_or_create_dir_or_exit "${log_dir}/${SUBDIR}"
  done

  echo_ok_verbose "Folder structure created successfully"
}
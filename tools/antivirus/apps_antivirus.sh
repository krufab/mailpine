#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function configure_antivirus {
  echo_ok "Configuring antivirus"
  local config_file="${1}"
  local apps_dir="${2}"
  local data_dir="${3}"
  local log_dir="${4}"

  local app_dir="${apps_dir}/antivirus"

  copy_template "${app_dir}"

  (
    unset TZ

    source "${app_dir}/.env"
    
    set_MP_DATA_DIR_variable "${app_dir}" "${data_dir}"
    set_MP_LOG_DIR_variable "${app_dir}" "${log_dir}"
    set_TZ_variable "${config_file}" "${app_dir}"
  )
  echo_ok_verbose "Antivirus configuration completed successfully"
}
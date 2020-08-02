#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare TICK="✅" # ✅
declare TICK_VERBOSE="\xE2\x9C\x94" # ✔
declare CROSS="\u274c" # ❌
#declare X2="\xE2\x9D\x8C"
#declare X="\xE2\x9C\x94"
#declare INFO="ⓘ"
declare INFO="👀"

export TICK
export CROSS
export INFO

function echo_error {
  echo -e "${CROSS} ${*}" >&2
}

function echo_info {
  echo -e " ${INFO} ${*}"
}

function echo_info_verbose {
  if [[ "${VERBOSE}" == "1" ]]; then
    echo -e " ${INFO} ${*}"
  fi
}

function echo_ok {
  echo -e "\e[1;32m${TICK}\e[0m ${*}"
}

function echo_ok_verbose {
  if [[ "${VERBOSE}" == "1" ]]; then
    echo -e " \e[1;32m${TICK_VERBOSE}\e[0m ${*}"
  fi
}

function check_or_create_dir_or_exit {
  local the_dir="${1}"

  if [[ -d "${the_dir}" ]]; then
    echo_ok_verbose "'${the_dir}' already created"
  else
    if mkdir -p "${the_dir}"; then
      echo_ok_verbose "'${the_dir}' directory created"
    else
      echo_error "Directory '${the_dir}' could not be created"
      exit 1
    fi
  fi
}

function copy_template {
  local app_dir="${1}"

  if [[ ! -f "${app_dir}/.env" ]]; then
    cp "${app_dir}/.env.template" "${app_dir}/.env"
  fi
}

function set_MP_DATA_DIR_variable {
  local app_dir="${1}"
  local data_dir="${2}"

  if [[ -z "${MP_DATA_DIR}" ]]; then
    sed -i -e "s|^MP_DATA_DIR.*$|MP_DATA_DIR=${data_dir}|g" "${app_dir}/.env"
  fi
}

function set_MP_LOG_DIR_variable {
  local app_dir="${1}"
  local log_dir="${2}"

  if [[ -z "${MP_LOG_DIR}" ]]; then
    sed -i -e "s|^MP_LOG_DIR.*$|MP_LOG_DIR=${log_dir}|g" "${app_dir}/.env"
  fi
}

function set_TZ_variable {
  local config_file="${1}"
  local app_dir="${2}"
  local timezone

  if [[ -z "${TZ}" ]]; then
    timezone="$(yq r "${config_file}" 'config.timezone')"
    sed -i -e "s|^TZ.*$|TZ=${timezone}|g" "${app_dir}/.env"
  fi
}

function check_config_version {
  echo_ok "Checking configuration file version"

  local CONFIG_FILE MIN_CONFIG_VERSION
  local CONFIG_VERSION

  CONFIG_FILE="${1}"
  MIN_CONFIG_VERSION="${2}"

  CONFIG_VERSION="$(yq r "${CONFIG_FILE}" 'version')"

  if [[ "${MIN_CONFIG_VERSION}" != "${CONFIG_VERSION}" ]]; then
    echo_error "Wrong configuration file version."
    echo_info "You have: '${CONFIG_VERSION}'. Expected: '${MIN_CONFIG_VERSION}'."
    exit 1
  fi
  echo_ok_verbose "Configuration file version check completed successfully"
}

function get_verbose_value {
  local CONFIG_FILE="${1}"
  local VERBOSITY_LEVEL

  VERBOSITY_LEVEL=$(yq r "${CONFIG_FILE}" 'config.verbosity_level')
  if [[ -z "${VERBOSITY_LEVEL}" ]]; then
    echo "1"
  else
    echo "${VERBOSITY_LEVEL}"
  fi
}

function run_step_single {
  local MP_P_ALL="${1}"
  local MP_P_SEL="${2}"
  local STEP="${3}"

  [[ "${MP_P_ALL}" != "-" ]] || [[ "${MP_P_SEL}" == *"${STEP}"* ]]
}

function run_step {
  local MP_P_ALL="${1}"
  local MP_P_SEL="${2}"
  local STEPS="${3}"
  local STEP

  for STEP in ${STEPS}; do
    if run_step_single "${MP_P_ALL}" "${MP_P_SEL}" "${STEP}"; then
      return 0
    fi
  done

  return 1
}

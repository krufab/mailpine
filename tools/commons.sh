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

function echo_error() {
  echo -e "${CROSS} ${*}" >&2
}

function echo_info() {
  echo -e " ${INFO} ${*}"
}

function echo_info_verbose() {
  if [[ "${VERBOSE}" == "1" ]]; then
    echo -e " ${INFO} ${*}"
  fi
}

function echo_ok() {
  echo -e "\e[1;32m${TICK}\e[0m ${*}"
}

function echo_ok_verbose() {
  if [[ "${VERBOSE}" == "1" ]]; then
    echo -e " \e[1;32m${TICK_VERBOSE}\e[0m ${*}"
  fi
}

function check_or_create_dir_or_exit() {
  local THE_DIR
  THE_DIR="${1}"

  if [[ -d "${THE_DIR}" ]]; then
    echo_ok_verbose "'${THE_DIR}' already created"
  else
    if mkdir -p "${THE_DIR}"; then
      echo_ok_verbose "'${THE_DIR}' directory created"
    else
      echo_error "Directory '${THE_DIR}' could not be created"
      exit 1
    fi
  fi
}

function copy_template() {
  local APP_DIR

  APP_DIR="${1}"

  if [[ ! -f "${APP_DIR}/.env" ]]; then
    cp "${APP_DIR}/.env.template" "${APP_DIR}/.env"
  fi
}

function set_MP_DATA_DIR_variable() {
  local CONFIG_FILE APP_DIR DATA_DIR

  CONFIG_FILE="${1}"
  APP_DIR="${2}"
  DATA_DIR="${3}"

  if [[ -z "${MP_DATA_DIR}" ]]; then
    sed -i -e "s|^MP_DATA_DIR.*$|MP_DATA_DIR=${DATA_DIR}|g" "${APP_DIR}/.env"
  fi
}

function set_TZ_variable() {
  local CONFIG_FILE APP_DIR
  local TIMEZONE

  CONFIG_FILE="${1}"
  APP_DIR="${2}"

  if [[ -z "${TZ}" ]]; then
    TIMEZONE="$(yq r "${CONFIG_FILE}" 'config.timezone')"
    sed -i -e "s|^TZ.*$|TZ=${TIMEZONE}|g" "${APP_DIR}/.env"
  fi
}

function check_config_version() {
  echo_ok "Checking configuration file version"

  local CONFIG_FILE MIN_CONFIG_VERSION
  local CONFIG_VERSION

  CONFIG_FILE="${1}"
  MIN_CONFIG_VERSION="${2}"

  CONFIG_VERSION=$(yq r "${CONFIG_FILE}" 'version')

  if [[ "${MIN_CONFIG_VERSION}" != "${CONFIG_VERSION}" ]]; then
    echo_error "Wrong configuration file version."
    echo_info "You have: '${CONFIG_VERSION}'. Expected: '${MIN_CONFIG_VERSION}'."
    exit 1
  fi
  echo_ok_verbose "Configuration file version check completed cuccessfully"
}

function get_verbose_value() {
  local CONFIG_FILE
  local VERBOSITY_LEVEL

  CONFIG_FILE="${1}"

  VERBOSITY_LEVEL=$(yq r "${CONFIG_FILE}" 'config.verbosity_level')
  if [[ -z "${VERBOSITY_LEVEL}" ]]; then
    echo "1"
  else
    echo "${VERBOSITY_LEVEL}"
  fi
}

function run_step() {
  local MP_P_ALL="${1}"
  local MP_P_SEL="${2}"
  local STEP="${3}"

  [[ "${MP_P_ALL}" != "-" ]] || [[ "${MP_P_SEL}" == *"${STEP}"* ]]
}
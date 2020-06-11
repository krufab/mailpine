#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

#declare TICK="\xE2\x9C\x94" # ✔
declare TICK="✅" # ✅
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
  echo -e "${INFO} ${*}"
}

function echo_ok() {
  echo -e "${TICK} ${*}"
}

function check_or_create_dir_or_exit() {
  local THE_DIR
  THE_DIR="${1}"

  if [[ -d "${THE_DIR}" ]]; then
    echo_ok "'${THE_DIR}' already created"
  else
    if mkdir -p "${THE_DIR}"; then
      echo_ok "'${THE_DIR}' directory created"
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
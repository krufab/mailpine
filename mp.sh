#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare MAIN_PATH
MAIN_PATH="$(dirname "$(readlink --canonicalize "${0}")")"
# shellcheck source=tools/help.sh
source "${MAIN_PATH}/tools/help.sh"

if [[ "${#}" -eq 0 ]]; then
  print_main_help
  exit 0
fi

declare ACTION=""

while [[ ${#} -gt 0 ]]; do
  case "${1}" in
  c|configure)
    shift 1
    ACTION="configure"
    break
    ;;
  h|-h|help|--help)
    print_main_help
    exit 0
    ;;
  r|run)
    shift 1
    ACTION="run"
    break
    ;;
  s|stop)
    shift 1
    ACTION="stop"
    break
    ;;
  u|update)
    shift 1
    ACTION="update"
    break
    ;;
  *)
    echo "Invalid option: '${1}'"
    exit 1
    ;;
  esac
done

"./tools/${ACTION}.sh" "${@}"
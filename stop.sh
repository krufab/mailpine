#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare -r THIS_PATH="$(dirname "$(readlink --canonicalize "${0}")")"

declare CONFIG_FILE="${THIS_PATH}/config.yml"

declare APPS_DIR="${THIS_PATH}/apps"

# shellcheck source=./tools/commons.sh
source "${THIS_PATH}/tools/commons.sh"
# shellcheck source=./tools/names.sh
source "${THIS_PATH}/tools/names.sh"

(
  cd apps/traefik/
  PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "traefik")"
  docker-compose --project-name "${PROFILE}" stop
)
(
  cd apps/mariadb/
  PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mariadb")"
  docker-compose --project-name "${PROFILE}" stop
)
(
  cd apps/mail/
  PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "mail")"
  docker-compose --project-name "${PROFILE}" stop
)
(
  cd apps/web/
  PROFILE="$(get_MP_D_PROFILE_x "${CONFIG_FILE}" "web")"
  docker-compose --project-name "${PROFILE}" stop
)

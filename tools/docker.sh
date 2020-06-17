#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

function check_mailpine_tools() {
  echo_ok "Checking mailpine tools image"
  if ! docker image inspect mailpine-tools:latest > /dev/null 2>&1; then
    echo_info "Building mailpine-tools:latest image"
    docker build -t mailpine-tools:latest -f tools/Dockerfile tools/ > /dev/null
  fi
  echo_ok_verbose "Docker image available"
}
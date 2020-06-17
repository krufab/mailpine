#!/usr/bin/env sh

set -euo pipefail

mkdir -p /data/opendkim
mkdir -p /var/run/opendkim/

chown -R opendkim:opendkim /data/opendkim

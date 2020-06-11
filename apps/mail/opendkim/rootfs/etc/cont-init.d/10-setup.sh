#!/usr/bin/env sh

set -euo pipefail

mkdir -p /data/opendkim
mkdir -p /var/run/opendkim/

#cp -R /tmp/mail/opendkim /data/opendkim

chown -R opendkim:opendkim /data/opendkim

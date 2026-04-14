#!/usr/bin/env sh

mkdir -p /run/clamav
chown -R clamav:clamav /data/antivirus
chown -R clamav:clamav /log/antivirus
chown -R clamav:clamav /run/clamav

echo "[INFO] Scanning services"
exec s6-svscan /etc/services.d
# This never terminates

exit 0

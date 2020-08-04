#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

declare -a HOSTS_TO_CHECK=(
#"antivirus"
"${MP_DATABASE_HOST}"
#"fail2ban"
"opendkim"
"opendmarc"
"unbound"
)

for HOST_TO_CHECK in "${HOSTS_TO_CHECK[@]}"; do
  # Check mariadb/postgres hostname
  if ! grep -q "${HOST_TO_CHECK}" /etc/hosts; then
    echo "[INFO] ${HOST_TO_CHECK} hostname not found in /etc/hosts"
    IP=$(dig A "${HOST_TO_CHECK}" +short +search)
    if [[ -n "${IP}" ]]; then
      echo "[INFO] Container IP found, adding a new record in /etc/hosts"
      echo "${IP} ${HOST_TO_CHECK}" >> /etc/hosts
    else
      echo "[WARNING] Container IP not found with embedded DNS server... Abort!"
      echo "[WARNING] Check your ${HOST_TO_CHECK} environment variable"
      #exit 1
    fi
  else
    echo "[INFO] ${HOST_TO_CHECK} hostname found in /etc/hosts"
  fi
done

IP="$(dig A "unbound" +short +search)"

echo "Use unbound"
# Use the local DNS server
echo "nameserver ${IP}" | tee /etc/resolv.conf \
                              /data/mail/postfix/spool/etc/resolv.conf \
                              >/dev/null

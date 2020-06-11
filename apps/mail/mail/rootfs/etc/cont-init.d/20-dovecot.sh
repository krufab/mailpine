#!/usr/bin/env bash

set -eEuo pipefail

echo "Substituting variables"

for SQL_CF in $(ls -p /etc/dovecot/sql/ | grep -v '/'); do
  envsubst '${MP_DATABASE_HOST},${MP_DATABASE_USER},${MP_DATABASE_PASSWORD},${MP_DATABASE_DB}' \
    < "/etc/dovecot/sql/${SQL_CF}" | sponge "/etc/dovecot/sql/${SQL_CF}"
done

envsubst '${MP_DOMAIN}' < /etc/dovecot/conf.d/10-ssl.conf | sponge /etc/dovecot/conf.d/10-ssl.conf
envsubst '${MP_DOMAIN}' < /etc/dovecot/conf.d/15-lda.conf | sponge /etc/dovecot/conf.d/15-lda.conf
envsubst '${MP_DOMAIN}' < /etc/dovecot/conf.d/20-lmtp.conf | sponge /etc/dovecot/conf.d/20-lmtp.conf

# process_min_avail = number of CPU cores, so that all of them will be used
DOVECOT_MIN_PROCESS=$(nproc)

# NbMaxUsers = ( 500 * nbCores ) / 5
# So on a two-core server that's 1000 processes/200 users
# with ~5 open connections per user
DOVECOT_MAX_PROCESS=$(($(nproc) * 500))

sed -i -e "s/DOVECOT_MIN_PROCESS/${DOVECOT_MIN_PROCESS}/" \
       -e "s/DOVECOT_MAX_PROCESS/${DOVECOT_MAX_PROCESS}/" /etc/dovecot/conf.d/10-master.conf

echo "[INFO] Dovecot debug mode is enabled"
#sed -i 's/^#//g' /etc/dovecot/conf.d/10-logging.conf

echo "Creating dovecot folders"
mkdir -p /data/mail/dovecot
if [[ -d /var/lib/dovecot ]]; then
  rm -rf /var/lib/dovecot
fi
ln -s /data/mail/dovecot /var/lib/dovecot

echo "Set permissions"
mkdir -p /var/run/dovecot
chown -R dovecot:dovecot /var/run/dovecot
#chown -R vmail:vmail /data/mail/sieve
#chmod +x /etc/dovecot/sieve/*.sh

# Avoid file_dotlock_open function exception
rm -f /data/mail/dovecot/instances

if [[ -f "/data/mail/dovecot/ssl-parameters.dat" ]]; then
  mv /data/mail/dovecot/ssl-parameters.dat /data/mail/dovecot/ssl-parameters.dat.backup
fi

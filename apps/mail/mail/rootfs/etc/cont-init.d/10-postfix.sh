#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

echo "Substituting variables"
envsubst '${MP_FQDN_MAIL}' < /etc/mailname | sponge /etc/mailname

for SQL_CF in $(ls -p /etc/postfix/sql/ | grep -v '/'); do
  envsubst '${MP_DATABASE_HOST},${MP_DATABASE_USER},${MP_DATABASE_PASSWORD},${MP_DATABASE_DB}' \
    < "/etc/postfix/sql/${SQL_CF}" | sponge "/etc/postfix/sql/${SQL_CF}"
done

envsubst '${MP_DOMAIN},${MP_FQDN_MAIL}' < /etc/postfix/main.cf | sponge /etc/postfix/main.cf
envsubst '${MP_FQDN_MAIL}' < /etc/postfix/header_checks | sponge /etc/postfix/header_checks
envsubst '${MP_DOMAIN}' < /etc/postfix/virtual | sponge /etc/postfix/virtual

echo "Updating spool"
rm -rf /var/spool/postfix
mkdir -p /data/mail/postfix
ln -s /data/mail/postfix/spool /var/spool/postfix

echo "Checking DNSSEC"
# DNSSEC is disabled
cat /etc/postfix/main.cf | grep smtp_tls_security_level
cat /etc/postfix/main.cf | grep smtp_dns_support_level

echo "Creating postfix folders"
# Create all needed folders in queue directory
POSTFIX_FOLDERS=(
etc
dev
maildrop
public
usr
usr/lib
usr/lib/sasl2
usr/lib/zoneinfo
)
for subdir in "${POSTFIX_FOLDERS[@]}" ; do
  mkdir -p  "/data/mail/postfix/spool/${subdir}"
  chmod 755 "/data/mail/postfix/spool/${subdir}"
done

echo "Add etc files to Postfix chroot jail"
# Add etc files to Postfix chroot jail
cp -f /etc/services /data/mail/postfix/spool/etc/services
cp -f /etc/hosts /data/mail/postfix/spool/etc/hosts

echo "Build header_checks and virtual index files"
# Build header_checks and virtual index files
postmap /etc/postfix/header_checks
newaliases
postmap /etc/postfix/virtual

#postmap /etc/postfix/aliases
#postalias /etc/postfix/aliases

echo "Setting permissions"
# Set permissions
# This fails on mac
chgrp -R postdrop /data/mail/postfix/spool/maildrop
chgrp -R postdrop /data/mail/postfix/spool/public
postfix set-permissions

echo "Use unbound"
# Use the local DNS server
#echo "nameserver unbound" | tee /etc/resolv.conf \
#                                /data/mail/postfix/spool/etc/resolv.conf \
#                                ;#>/dev/null

echo "Ready to start postfix"
#exec postfix -c /etc/postfix start-fg &>/dev/null
#exec postfix -c /etc/postfix start-fg

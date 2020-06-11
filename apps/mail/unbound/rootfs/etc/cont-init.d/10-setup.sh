#!/usr/bin/env sh

set -euo pipefail

mkdir -p /data/unbound/keys

# Update the root trust anchor to perform cryptographic DNSSEC validation
echo "Receiving anchor key..."
set +e
/usr/sbin/unbound-anchor -v -a /data/unbound/root.key
set -e
#cat /data/unbound/root.key

# Get a copy of the latest root DNS servers list
echo "Receiving root hints..."
curl -s -o /data/unbound/root.hints https://www.internic.net/domain/named.cache; # > /dev/null

echo "Correct ownership of /etc/unbound"
# Set permissions
chmod 775 /data/unbound
chown -R unbound:unbound /data/unbound

echo "Enable remote control and init keys"
/usr/sbin/unbound-control-setup -d /data/unbound/keys/

#mkdir -p /data/postfix/spool/etc/

/usr/sbin/unbound-checkconf /etc/unbound/unbound.conf

# https://github.com/extremeshok/docker-unbound/blob/master/rootfs/docker-entrypoint.sh

# Use the local DNS server
#echo "nameserver 127.0.0.1" | tee /etc/resolv.conf \
#                                  /data/postfix/spool/etc/resolv.conf \
#                                  ;#>/dev/null

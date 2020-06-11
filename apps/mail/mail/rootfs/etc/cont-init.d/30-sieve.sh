#!/usr/bin/env bash

set -eEuo pipefail

mkdir -p /data/mail/sieve

# Default rule
cat > /data/mail/sieve/default.sieve <<EOF
require ["fileinto"];
if anyof(
    header :contains ["X-Spam-Flag"] "YES",
    header :contains ["X-Spam"] "Yes",
    header :contains ["Subject"] "*** SPAM ***"
)
{
    fileinto "Spam";
    stop;
}
EOF

if [[ -s /data/mail/sieve/custom.sieve ]]; then
  cp -f /data/mail/sieve/custom.sieve /data/mail/sieve/default.sieve
fi

echo "Compiling sripts"
# Compile sieve scripts
sievec /data/mail/sieve/default.sieve
sievec /etc/dovecot/sieve/report-ham.sieve
sievec /etc/dovecot/sieve/report-spam.sieve

echo "Set permissions"
chown -R vmail:vmail /data/mail/sieve
chmod +x /etc/dovecot/sieve/*.sh
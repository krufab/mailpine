2024-01-31:
- Updated poxtfix main.cf to avoid being bounced back from spamhaus

2020-08-17:
- Improved postfix fail2ban filter

2020-08-04:
- Added support for external services (#14)
- Replaced launch commands with a single one 
- Improved bash code

2020-08-01:
- Added clamav
- Added fail2ban
- Added log folder
- Improved scripts and configurations

2020-07-10:
- Removed OSCP must staple option from certificate requests as not supported by dovecot nor postfix (#10)
  - Check: https://serverfault.com/queùstions/830434/do-postfix-and-dovecot-support-ocsp-stapling/878378
- Set port 993 as default mail port
- Changed sql init file to be a template (#8)
- Removed gzip support from nginx due to result from testssl
  - BREACH (CVE-2013-3587) potentially NOT ok, "gzip" HTTP compression detected

2020-07-01:
- Improved nginx configuration (#5).
  - Cleaned nginx .conf files
  - Added endpoint for letsencrypt
  - Added secure headers for postfixadmin & phpmyadmin
  - Added (almost) secure headers to roundcubemail
- configure.sh creates a link to the ca.cer file to be used for OCSP stapling

2020-06-28:
- OCSP stapling
- HSTS support
- acme.sh working with nginx on
- Added help functions (#2)

2020-06-27:
- Removed traefik as it wasn't possible to configure the SSL part correctly (no OCSP support and difficult configuration for hsts)
- Reached A+ 100% score with testssl.sh and ssllabs
- Request Let's Encrypt certificates using elliptic curves cryptography 

2020-06-17:
- Selectively configure services (i.e. `configure.sh -s opendkim`)
- Folder organization improvement
- Improved postfixadmin configuration
- Postfix verbose

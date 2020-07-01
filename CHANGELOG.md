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

2020-06-28:
- OCSP stapling
- HSTS support
- acme.sh working with nginx on

2020-06-27:
- Removed traefik as it wasn't possible to configure the SSL part correctly (no OCSP support and difficult configuration for hsts)
- Reached A+ 100% score with testssl.sh and ssllabs
- Request Let's Encrypt certificates using elliptic curves cryptography 

2020-06-17:
- Selectively configure services (i.e. `configure.sh -s opendkim`)
- Folder organization improvement
- Improved postfixadmin configuration
- Postfix verbose

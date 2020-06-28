# Mailpine - (alpha version)

Pre-configured A+ Alpine based mail server with web frontend for user managements.
Uses Let's Encrypt certificates.

## Security

- A+ in with 100% score with ssl labs and testssl.sh
- Let's Encrypt certificates
- TLS 1.2
- DH 4096
- ECDH 384
- OCSP Stapling
- HTTP Strict Transport Security (HSTS)

## Components:
- postfix
- dovecot
- opendkim
- opendmarc
- spf
- postfixadmin
- roundcubemail
- nginx
- mariadb
- phpmyadmin
- <del>traefik</del>

## Quickstart

```bash
cp config.template.yml config.yml

vi config.yml

./configure.sh

./run.sh
```

## Description

### Required tools
- nc (netcat)
- readlink with -f support (from coreutils package)
- yq (https://github.com/mikefarah/yq)

### Configuration steps

```bash
./configure.sh [options]
./configure.sh --help

Mailpine - configuration
Usage: ./configure.sh [options]

 -d --debug   Set services in debug mode
 -h --help    This help
 -l --list    Show the list of available services
 -r --run     Run services after configuration
 -R --restart Restart services after configuration
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
 -v --verbose Print out a verbose output of this script
```

- Uses acme.sh to request SSL certificates
- Checks and creates opendkim keys
- Checks and suggests TXT field for opendmarc 
- Checks and suggests TXT field for spf 
- <del>Configures traefik</del>
- Configures mariadb
- Configures postfix, dovecot, opendkim, opendmarc, unbound
- Configures nginx, postfixadmin, roundcubemail, phpmyadmin

### Run steps

```bash
./run.sh [options]
./run.sh --help

Mailpine - run
Usage: ./run.sh [options]

 -h --help    This help
 -l --list    Show the list of available services
 -R --restart Restart services after configuration
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
```

- <del>Starts traefik</del>
- Starts mariadb
- Starts postfix, dovecot, opendkim, opendmarc, unbound
- Starts nginx, postfixadmin, roundcubemail, phpmyadmin

### Stop steps

```bash
./stop.sh [options]
./stop.sh --help

Mailpine - stop
Usage: ./stop.sh [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
```

- Stops nginx, postfixadmin, roundcubemail, phpmyadmin
- Stops postfix, dovecot, opendkim, opendmarc, unbound
- Stops mariadb
- <del>Stops traefik</del>

### Useful links
- https://ssl-config.mozilla.org/
- https://www.digitalocean.com/community/tools/nginx
- https://community.letsencrypt.org/t/howto-a-with-all-100-s-on-ssl-labs-test-using-nginx-mainline-stable/55033
- https://www.ssllabs.com/ssltest/analyze.html
- https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide
- https://stackoverflow.com/questions/41930060/how-do-you-score-a-with-100-on-all-categories-on-ssl-labs-test-with-lets-encry

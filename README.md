# Mailpine - (alpha version)

Alpine based mail server

Components:
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
- traefik

## Instructions

```bash
cp config.template.yml config.yml

vi config.yml

./configure.sh

./run.sh
```

## Description

### Configuration strep

- Use acme.sh to request SSL certificates
- Checks and creates opendkim keys
- Checks and suggests TXT field for opendmarc 
- Checks and suggests TXT field for spf 
- Configures traefik
- Configures mariadb
- Configures postfix, dovecot, opendkim, opendmarc, unbound
- Configures nginx, postfixadmin, roundcubemail, phpmyadmin

### Run step

- Starts traefik
- Starts mariadb
- Starts postfix, dovecot, opendkim, opendmarc, unbound
- Starts nginx, postfixadmin, roundcubemail, phpmyadmin

### Run step

- Stops traefik
- Stops mariadb
- Stops postfix, dovecot, opendkim, opendmarc, unbound
- Stops nginx, postfixadmin, roundcubemail, phpmyadmin

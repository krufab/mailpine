# Mailpine - (alpha version)

A+ Alpine based mail server

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
- <del>traefik</del>

## Instructions

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

- Uses acme.sh to request SSL certificates
- Checks and creates opendkim keys
- Checks and suggests TXT field for opendmarc 
- Checks and suggests TXT field for spf 
- <del>Configures traefik</del>
- Configures mariadb
- Configures postfix, dovecot, opendkim, opendmarc, unbound
- Configures nginx, postfixadmin, roundcubemail, phpmyadmin

### Run steps

- <del>Starts traefik</del>
- Starts mariadb
- Starts postfix, dovecot, opendkim, opendmarc, unbound
- Starts nginx, postfixadmin, roundcubemail, phpmyadmin

### Stop steps

- Stops nginx, postfixadmin, roundcubemail, phpmyadmin
- Stops postfix, dovecot, opendkim, opendmarc, unbound
- Stops mariadb
- <del>Stops traefik</del>

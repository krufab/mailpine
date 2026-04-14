# Mailpine - (alpha version)
Pre-configured A+ Alpine based mail server with web frontend for user managements.
Uses Let's Encrypt certificates.

## Security
- A+ in with 100% score with ssl labs and testssl.sh
- Let's Encrypt certificates
- TLS 1.2
- DH 4096
- ECDH 384
- <del>OCSP Stapling</del>
- HTTP Strict Transport Security (HSTS)

## Components:
- mail
  - postfix
  - dovecot
  - opendkim
  - opendmarc
  - spf
  - unbound
- database
  - mariadb
- security
  - clamav
  - fail2ban
- web
  - postfixadmin
  - roundcubemail
  - nginx
  - phpmyadmin
- <del>traefik</del>

## Quickstart
```bash
cp config.template.yml config.yml

vi config.yml

./mp.sh configure

./mp.sh run
```

## Description
### Required tools
- nc (netcat)
- readlink with -f support (from coreutils package)
- yq (https://github.com/mikefarah/yq)

### Configuration command
```bash
./mp.sh configure [options]
./mp.sh configure --help

Mailpine - Configure mailpine
Usage: ./tools/configure.sh c|configure [options]

 -d --debug   Set services in debug mode
 -h --help    This help
 -l --list    Show the list of available services
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
- Configures clamav, fail2ban

### Run command
```bash
./mp.sh r|run [options]
./mp.sh r|run --help

Mailpine - Run mailpine
Usage: ./tools/run.sh r|run [options]

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
- Starts clamav, fail2ban

### Stop command
```bash
./mp.sh s|stop [options]
./mp.sh s|stop --help

Mailpine - Stop mailpine
Usage: ./tools/stop.sh s|stop [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
```

- Stops nginx, postfixadmin, roundcubemail, phpmyadmin
- Stops postfix, dovecot, opendkim, opendmarc, unbound
- Stops mariadb
- Stops clamav, fail2ban
- <del>Stops traefik</del>

### Update command
```bash
./mp.sh u|update [options]
./mp.sh u|update --help

Mailpine - Stop, configure and relaunch mailpine
Usage: ./tools/update.sh u|update [options]

 -h --help    This help
 -l --list    Show the list of available services
 -s --service [service] Configure / run / restart the specific service
                Can be used multiple times
```
Utility to stop, configure and restart services

## Useful links
- https://ssl-config.mozilla.org/
- https://www.digitalocean.com/community/tools/nginx
- https://community.letsencrypt.org/t/howto-a-with-all-100-s-on-ssl-labs-test-using-nginx-mainline-stable/55033
- https://www.ssllabs.com/ssltest/analyze.html
- https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide
- https://stackoverflow.com/questions/41930060/how-do-you-score-a-with-100-on-all-categories-on-ssl-labs-test-with-lets-encry

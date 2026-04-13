#

## Tutorials

### Spamhaus

https://www.spamhaus.org/lookup/

### Dkim & dmarc & spf

- https://petermolnar.net/howto-spf-dkim-dmarc-postfix/

#### Commands

Generate dkim pair:

`opendkim-genkey -b 2048 -d domain.com -s domain.com.dkim`

dig for spf
dig +short TXT fabio.is
dig +short TXT @dns1.registrar-servers.com. fabio.is
spfquery --scope mfrom --id fabio@fabio.is --ip 51.15.79.253 --helo-id mail.fabio.is

opendkim-testkey -d your-domain.com -s default -vvv

## DNS config

(Dkim)
TXT | mail._domainkey. | v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCwjuWHKzx/ikA4Qw9i/wn722uNV0poRkh7/0KdyUO46BbHZAIbQajoZh+ppbE7hCaKd/EYGN74mjGYx5XyXZ+36EBsxNk2ID7+bExONTwDfVlvTFZZ7Bu4bc9FKXnB+5vF5LQv64KK0ZTueCo1CrDBqOmdRLDzXoTPUwSUQu6XKwIDAQAB

(Dmarc)
TXT | _dmarc. | v=DMARC1; p=quarantine; pct=20; adkim=s; aspf=r; fo=1; rua=mailto:postmaster@fabio.is; ruf=mailto:forensic@fabio.is;

(SPF)
TXT | @ | v=spf1 mx a ip4:51.15.79.253 -all
TXT | *. | v=spf1 mx a ip4:51.15.79.253 -all


##
1. https://www.appmaildev.com/en/spf
1. https://www.kitterman.com/spf/validate.html?
1. https://www.spfwizard.net/
1. https://www.checktls.com/
1. https://pingability.com/zoneinfo.jsp?domain=fabio.is
1. https://dnsviz.net/d/fabio.is/dnssec/


https://github.com/obi12341/docker-unbound/blob/master/assets/unbound.conf
https://github.com/MatthewVance/unbound-docker/blob/master/1.10.0/unbound.sh

https://github.com/mailcow/mailcow-dockerized


https://pi-hole.net/

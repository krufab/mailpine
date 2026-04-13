# Fail2ban

## Wiki
https://github.com/fail2ban/fail2ban/wiki
https://www.fail2ban.org/wiki/index.php/Commands

## Bans
Manually Ban \<IP> for \<JAIL>: `set <JAIL> banip <IP>`

Unban \<IP> for \<JAIL>: `fail2ban-client set <JAIL> unbanip <IP>`
fail2ban-client set mp_nginx unbanip 81.11.204.63

## Jails examples
https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04

## Regex tester python
https://www.debuggex.com/?flavor=python

## Docker
https://github.com/crazy-max/docker-fail2ban/blob/master/entrypoint.sh

## Tools
Check bans: all-fail2ban.sh
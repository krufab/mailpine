#!/usr/bin/env sh

JAILS="$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')"
TOTAL="$(echo "${JAILS}" | wc -w)"

while true; do
  CURRENT=1
  for JAIL in ${JAILS}; do
    clear
    echo "${CURRENT}/${TOTAL}"
    fail2ban-client status "${JAIL}"
    sleep 5
    CURRENT=$(( CURRENT + 1 ))
  done
done

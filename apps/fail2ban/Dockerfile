FROM alpine:3.12

RUN set -e; \
  apk -U upgrade --no-cache; \
  apk add --no-cache \
    fail2ban \
    iptables \
    tzdata \
    whois \
  ; \
  rm -rf /etc/fail2ban/jail.d/*.conf;

COPY rootfs /

ENTRYPOINT ["fail2ban-server"]

CMD ["-f", "-x", "-v", "start" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD fail2ban-client ping || exit 1

FROM alpine:3.11 AS overlay

RUN wget -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-amd64.tar.gz

#-----------------

FROM alpine:3.11 AS build

RUN apk add --no-cache \
  gettext \
  moreutils

#-----------------

FROM alpine:3.11

RUN addgroup -g 1000 vmail \
  && adduser -h /data/mail -G vmail -u 1000 -D vmail \
  && passwd -u vmail

RUN apk add --no-cache \
  bash \
  busybox \
  dovecot \
  dovecot-lmtpd \
  dovecot-mysql \
#  dovecot-submissiond \
# Sieve related
  dovecot-pigeonhole-plugin \
  email \
  libintl \
  postfix \
  postfix-mysql \
  postfix-pcre \
  tzdata

COPY --from=overlay /tmp/s6-overlay.tar.gz /tmp/

RUN tar -xzf /tmp/s6-overlay.tar.gz -C / \
  && rm -rf /tmp/s6-overlay.tar.gz

COPY --from=build /usr/bin/envsubst /usr/bin/sponge /usr/bin/

COPY rootfs /

WORKDIR /data/mail

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_KEEP_ENV=1

ENTRYPOINT ["/init"]

RUN apk add --no-cache \
  bind-tools
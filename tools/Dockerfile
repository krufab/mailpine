FROM alpine:3.15

RUN set -e; \
  addgroup -g 1000 vmail; \
  adduser -h /data/mail -G vmail -u 1000 -D vmail; \
  passwd -u vmail

RUN set -e; \
  apk -U upgrade --no-cache; \
  apk add --no-cache \
    bash \
    grep \
    libspf2-tools \
    opendkim-utils \
    opendmarc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    openssl \
    sed \
  ;

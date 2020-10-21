FROM alpine:3.12

RUN addgroup -g 1000 vmail \
  && adduser -h /data/mail -G vmail -u 1000 -D vmail \
  && passwd -u vmail

RUN apk add --no-cache \
  bash \
  grep \
  libspf2-tools \
  opendkim-utils \
  opendmarc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  openssl \
  sed

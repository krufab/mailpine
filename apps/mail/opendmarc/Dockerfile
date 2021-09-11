FROM alpine:3.14.2 AS build

RUN wget -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-amd64.tar.gz

FROM alpine:3.14.2

#echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
#apk add package-name@testing

RUN  set -e; \
  apk -U upgrade --no-cache; \
  apk add --no-cache \
    busybox \
    opendmarc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    tzdata \
  ;

COPY --from=build /tmp/s6-overlay.tar.gz /tmp/

RUN set -e; \
  tar -xzf /tmp/s6-overlay.tar.gz -C /; \
  rm -rf /tmp/s6-overlay.tar.gz

COPY rootfs /

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_KEEP_ENV=1s

EXPOSE 8893

ENTRYPOINT ["/init"]

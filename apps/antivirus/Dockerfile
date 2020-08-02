FROM alpine:3.11 AS overlay

RUN wget -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.21.7.0/s6-overlay-amd64.tar.gz

#-----------------

FROM alpine:3.12

RUN apk add --no-cache \
  clamav \
  clamav-libunrar \
  clamav-milter \
  freshclam \
  tzdata

COPY --from=overlay /tmp/s6-overlay.tar.gz /tmp/

RUN tar -xzf /tmp/s6-overlay.tar.gz -C / \
  && rm -rf /tmp/s6-overlay.tar.gz

COPY rootfs /

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_KEEP_ENV=1

ENTRYPOINT ["/init"]

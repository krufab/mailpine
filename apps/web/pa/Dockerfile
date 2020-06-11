FROM postfixadmin:3.2-fpm-alpine

RUN apk add --no-cache \
    imap-dev \
    tzdata \
  && docker-php-ext-install imap

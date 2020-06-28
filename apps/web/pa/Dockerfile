FROM postfixadmin:3.2.4-fpm-alpine

RUN apk add --no-cache \
  tzdata
#    imap-dev \
#    tzdata \
#  && docker-php-ext-install imap


RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		imap-dev \
		krb5-dev \
		libressl-dev \
	; \
	docker-php-ext-configure \
		imap --with-imap-ssl --with-kerberos \
	; \
	docker-php-ext-install -j "$(nproc)" \
		imap \
	; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .postfixadmin-phpexts-rundeps $runDeps; \
	apk del .build-deps

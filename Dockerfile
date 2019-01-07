FROM nginx:latest
LABEL maintainer="David <david@cninone.com>"

RUN echo 'deb http://deb.debian.org/debian buster main \n \
deb http://security.debian.org/debian-security buster/updates main \n \
deb http://deb.debian.org/debian buster-updates main \n' \
	> /etc/apt/sources.list.d/buster.list \
	; { \
		echo 'Package: *'; \
		echo 'Pin: release n=buster'; \
		echo 'Pin-Priority: -10'; \
		echo; \
		echo 'Package: libargon2*'; \
		echo 'Pin: release n=buster'; \
		echo 'Pin-Priority: 990'; \
	} > /etc/apt/preferences.d/argon2-buster

ENV TMP_TOOLS \
    autoconf \
    build-essential \
    pkg-config
ENV DEPS \
    libssl-dev libcurl4-openssl-dev libxml2-dev libreadline7 \
	libreadline-dev libzip-dev libzip4 \
	zlib1g-dev libpq-dev libedit-dev libsodium-dev \
	libsqlite3-dev libjpeg-dev libpng-dev libxpm-dev libargon2-dev
ENV SRC_DIR /php_src/php-7.3.0
RUN apt-get update && apt-get install -y $TMP_TOOLS $DEPS
COPY --from=novice/php $SRC_DIR $SRC_DIR
# php begin
WORKDIR $SRC_DIR
RUN make install && cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf \
	&& cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf \
	&& sed 's@NONE@/usr/local@g' -i /usr/local/etc/php-fpm.conf \
	&& mkdir -p /usr/local/etc/php/conf.d \
	&& cp -v php.ini-* /usr/local/etc/php/ \
	&& cp /usr/local/etc/php/php.ini-production /usr/local/lib/php.ini \
	&& pear config-set php_ini /usr/local/lib/php.ini \
	&& pecl config-set php_ini /usr/local/lib/php.ini \
	&& pecl install igbinary && yes | pecl install redis \
	&& pecl install mongodb \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $TMP_TOOLS \
    && rm -rf "${SRC_DIR}" /tmp/* /var/lib/apt/lists/*

# php end
WORKDIR /var/www

COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN rm -rf /var/log/nginx/* ; mkdir -p /var/www /run/php && chown -R www-data:www-data /var/www
	
VOLUME ["/var/www"]

EXPOSE 80 

COPY init /

ENTRYPOINT ["/init"]

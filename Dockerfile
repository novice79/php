FROM debian:stretch-slim
LABEL maintainer="David <david@cninone.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG       en_US.UTF-8
ENV LC_ALL	   "C.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update && apt-get install -y tzdata curl wget git procps net-tools gnupg \
	ca-certificates apt-transport-https 
ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone 

# nginx begin
RUN printf '%s\n' "deb http://nginx.org/packages/mainline/debian/ stretch nginx" >> /etc/apt/sources.list
RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
# nginx end

# COPY --from=php:fpm /usr/local /usr/local
# php begin
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
	} > /etc/apt/preferences.d/argon2-buster \
	&& mkdir /php_src
WORKDIR /php_src
RUN apt-get update && apt-get install -y autoconf build-essential curl libtool \
	libssl-dev libcurl4-openssl-dev libxml2-dev libreadline7 \
	libreadline-dev libzip-dev libzip4 nginx openssl \
	pkg-config zlib1g-dev libpq-dev libedit-dev libsodium-dev \
	libsqlite3-dev libjpeg-dev libpng-dev libxpm-dev libargon2-dev \
	&& apt autoremove -y ; rm -rf /var/lib/apt/lists/* 
ENV ver "7.3.0"
RUN wget http://sg2.php.net/distributions/php-$ver.tar.xz && tar Jxvf php-$ver.tar.xz 
WORKDIR /php_src/php-$ver
RUN ./configure \
    --enable-soap \
    --enable-mysqlnd \
    --enable-mbstring \
    --enable-phpdbg \
    --enable-shmop \
    --enable-sockets \
    --enable-ftp \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-pcntl \
    --enable-zip \
    --enable-bcmath \
    --enable-fpm \
    --with-jpeg-dir \
    --with-png-dir \
    --with-pdo-mysql \
    --with-pdo-mysql=mysqlnd \
    --with-pdo-pgsql=/usr/bin/pg_config \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --with-libzip=/usr/lib/x86_64-linux-gnu \
    --with-mhash \
    --with-zlib \
    --with-curl \
    --with-pear \
    --with-openssl \
    --with-libedit \
    --with-password-argon2 \
    --with-sodium=shared \
    --with-readline \
	&& make -j4 && make install
RUN cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf \
	&& cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf \
	&& sed 's@NONE@/usr/local@g' -i /usr/local/etc/php-fpm.conf \
	&& mkdir -p /usr/local/etc/php/conf.d \
	&& cp -v php.ini-* /usr/local/etc/php/ \
	&& cp /usr/local/etc/php/php.ini-production /usr/local/lib/php.ini \
	&& pear config-set php_ini /usr/local/lib/php.ini \
	&& pecl config-set php_ini /usr/local/lib/php.ini \
	&& pecl install igbinary && yes | pecl install redis \
	&& pecl install mongodb
# php end


COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www /run/php && chown -R www-data:www-data /var/www
	
VOLUME ["/var/www"]

EXPOSE 80 

COPY init /

ENTRYPOINT ["/init"]

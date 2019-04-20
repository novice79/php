FROM ubuntu:18.04
LABEL maintainer="novice <novice@piaoyun.shop>"

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

ENV LANG       en_US.UTF-8
ENV LC_ALL	   "C.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update -y && apt-get install -y language-pack-en-base tzdata

RUN mkdir -p  /var/log/nginx /run/php 

ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y nginx \
        php-cli php-common php php-mysql php-fpm php-curl php-gd \
        php-intl php-readline php-tidy php-json php-sqlite3 \
        php-bz2 php-mbstring php-xml php-zip php-opcache php-bcmath php-redis \
    && apt-get clean && apt-get autoclean && apt-get remove  \
    && rm -rf /var/lib/apt/lists/* 
    
RUN sed -i 's/^\(pm\.max_children\s*=\s*\).*$/\160/' /etc/php/7.2/fpm/pool.d/www.conf \
&& sed -i 's/^\(pm\.start_servers\s*=\s*\).*$/\120/' /etc/php/7.2/fpm/pool.d/www.conf \
&& sed -i 's/^\(pm\.min_spare_servers\s*=\s*\).*$/\120/' /etc/php/7.2/fpm/pool.d/www.conf \
&& sed -i 's/^\(pm\.max_spare_servers\s*=\s*\).*$/\130/' /etc/php/7.2/fpm/pool.d/www.conf \
&& sed -i 's/^;\(pm\.max_requests\s*=\s*\).*$/\1500/g' /etc/php/7.2/fpm/pool.d/www.conf \
&& sed -i 's/^;\(emergency_restart_threshold\s*=\s*\).*$/\110/g' /etc/php/7.2/fpm/php-fpm.conf \
&& sed -i 's/^;\(emergency_restart_interval\s*=\s*\).*$/\11m/g' /etc/php/7.2/fpm/php-fpm.conf \
&& sed -i 's/^;\(process_control_timeout\s*=\s*\).*$/\115s/g' /etc/php/7.2/fpm/php-fpm.conf

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY init.sh /

RUN chown -R www-data:www-data /var/www && chmod +x /init.sh \
    && touch /var/log/php_errors.log && chmod 666 /var/log/php_errors.log

VOLUME ["/var/www"]


EXPOSE 80 

ENTRYPOINT ["/init.sh"]

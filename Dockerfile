FROM php:fpm as my_php
WORKDIR /php_inst
RUN find /usr/local/ -type f -perm /a+x -exec ldd {} \; \
| grep "=> /" \
| awk '{print $3}' \
| sort \
| uniq \
| xargs -I '{}' cp --parents {} . \
&& cp -r --parents /usr/local .


FROM nginx:latest as my_nginx
WORKDIR /nginx_inst
RUN ldd `which nginx` \
| grep "=> /" \
| awk '{print $3}' \
| sort \
| uniq \
| xargs -I '{}' cp --parents {} . \
&& cp -r --parents /etc/nginx . \
&& cp `which nginx` --parents .


FROM debian:stretch-slim
LABEL maintainer="David <david@cninone.com>"

COPY --from=my_php /php_inst /
COPY --from=my_nginx /nginx_inst /

WORKDIR /var/www

COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/nginx /var/cache/nginx /var/www /run/php \
	&& chown -R www-data:www-data /var/www
	
VOLUME ["/var/www"]

EXPOSE 80 

COPY init /

ENTRYPOINT ["/init"]

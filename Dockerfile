FROM php:fpm as my_php

WORKDIR /php_inst
RUN find /usr/local/ -type f -perm /a+x -exec ldd {} \; \
| grep "=> /" \
| awk '{print $3}' \
| sort \
| uniq \
| xargs -I '{}' cp --parents {} . \
&& cp -r --parents /usr/local .


FROM nginx:latest
LABEL maintainer="David <david@cninone.com>"

COPY --from=my_php /php_inst /

WORKDIR /var/www

COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN rm -rf /var/log/nginx/* ; mkdir -p /var/www /run/php && chown -R www-data:www-data /var/www
	
VOLUME ["/var/www"]

EXPOSE 80 

COPY init /

ENTRYPOINT ["/init"]

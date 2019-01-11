FROM novice/php:build as my_php
WORKDIR /php_inst
# copy .so symlink & target files together
RUN find /usr/local/ -type f -perm /a+x -exec ldd {} \; \
| grep "=> /" \
| awk '{print $3}' \
| sort \
| uniq \
| xargs -I '{}' sh -c 'cp --parents `readlink -f {}` . ; cp --parents -P {} .' \
&& cp -r --parents /usr/local .


FROM nginx:latest as my_nginx
WORKDIR /nginx_inst
RUN ldd `which nginx` \
| grep "=> /" \
| awk '{print $3}' \
| sort \
| uniq \
| xargs -I '{}' sh -c 'cp --parents `readlink -f {}` . ; cp --parents -P {} .' \
&& cp -r --parents /etc/nginx . \
&& cp `which nginx` --parents . \
&& cp -r --parents /var/log/nginx .


FROM debian:stretch-slim
LABEL maintainer="David <david@cninone.com>"

# RUN apt-get update && apt-get install -y tzdata 
ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY --from=my_php /php_inst /
COPY --from=my_nginx /nginx_inst /

WORKDIR /var/www

COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/cache/nginx /var/www /run/php \
	&& chown -R www-data:www-data /var/www \
    && { \
            echo '[global]'; \
            echo 'error_log = /proc/self/fd/2'; \
            echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
            echo; \
            echo '[www]'; \
            echo '; if we send this to /proc/self/fd/1, it never appears'; \
            echo 'access.log = /proc/self/fd/2'; \
            echo; \
            echo 'clear_env = no'; \
            echo; \
            echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
            echo 'catch_workers_output = yes'; \
            echo 'decorate_workers_output = no'; \
        } | tee /usr/local/etc/php-fpm.d/docker.conf
	
VOLUME ["/var/www"]

EXPOSE 80 

COPY init.sh /

ENTRYPOINT ["/init.sh"]

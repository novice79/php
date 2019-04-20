

# ubuntu 18.04 stock nginx+php-fpm
docker run -p 10080:80 -d --name lep novice/php:ub

//or link in php src dir to container
docker run -p 10080:80 -d \
-v /data/php_src:/var/www:rw \
--name lep novice/php:ub
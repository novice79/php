#!/bin/bash
php-fpm -F &
pid_php=$!

nginx_v=`nginx -v 2>&1`
php_v=`php -v 2>&1`
cat <<EOT >> /var/www/index.php
<!DOCTYPE html> 
<html> 
<head> 
<meta charset="utf-8" /> 
<title>LEMP in docker test</title> 
<style> 
    body{ text-align:center} 
    .version{ margin:0 auto; border:1px solid #F00} 
</style> 
</head> 
<body> 
    lemp versions:
    <div class="version">    
    ${nginx_v}<br>
    ${php_v}<br>
    </div> 
    <br>
    <?php echo phpinfo(); ?>
</body> 
</html> 
EOT

nginx &
pid_nginx=$!

# no pgrep && ps
while [ 1 ]
do
    sleep 2
    SERVICE="nginx"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        "$SERVICE" &
        # send mail ?
    fi
    SERVICE="php-fpm"
    if ! pidof "$SERVICE" >/dev/null
    then
        echo "$SERVICE stopped. restart it"
        "$SERVICE" &
        # send mail ?
    fi
done
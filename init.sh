#!/bin/bash
php-fpm -F &
pid_php=$!

# write multiple lines to file
# {
#         echo '  directory "/var/cache/bind";'
#         echo '  listen-on { 127.0.0.1; };'
#         echo '  listen-on-v6 { none; };'
#         echo '  version "";'
#         echo '  auth-nxdomain no;'
#         echo '  forward only;'  
#         echo '  forwarders { 8.8.8.8; 8.8.4.4; };'
#         echo '  dnssec-enable no;'
#         echo '  dnssec-validation no;'
# } >> your_file.txt

# echo "
#     111
#     222
#   333
#   444
# " > aaa.txt

php_index="/var/www/index.php"
if [ ! -f $php_index ]; then
    nginx_v=`nginx -v 2>&1`
    php_v=`php -v 2>&1`
    cat <<EOT >> $php_index
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
fi
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
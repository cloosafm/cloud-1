#!/bin/sh

# INITIALIZATION ###############################

if [ ! -f "/build/.init" ] || [ "$(< "/build/.init")" != "1" ]
then

    sleep       10 && echo 1 > /build/.init

    cd          /var/www/public
    curl        -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
    chmod       +x /usr/local/bin/wp

    wp          --allow-root core download
    mv          ../wp-config.php . && rm -rf wp-config-sample.php

    wp          --allow-root core install \
                    --url=${WDP_URL_SCHEME}://${WDP_URL_HOST} --title=${WDP_TITLE} \
                    --admin_email=${WDP_ADMIN_EMAIL} --admin_user=${WDP_ADMIN_LOGIN} --admin_password=${WDP_ADMIN_PASSWORD} \
                    --skip-email

    wp          --allow-root user create ${WDP_USER_LOGIN} ${WDP_USER_EMAIL} --user_pass=${WDP_USER_PASSWORD} --role=author

    wp          --allow-root theme install ${WDP_THEME} --activate

    usermod     -d /var/www/public www-data
    chown       -R www-data:www-data /var/www/public

    sed         -i "s|/run/php/php8.2-fpm.sock|${WDP_DOCKER_PORT}|g" /etc/php/8.2/fpm/pool.d/www.conf
    sed         -i "s|;clear_env|clear_env|g" /etc/php/8.2/fpm/pool.d/www.conf

fi

# BOOT #########################################

php-fpm8.2 -F

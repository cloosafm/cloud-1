#!/bin/sh

# INITIALIZATION ###############################

if [ ! -f "/build/.init" ] || [ "$(< "/build/.init")" != "1" ]
then

    sleep       1 && echo 1 > /build/.init

    openssl     req -newkey rsa:4096 -x509 -sha256 -days 365 -noenc             \
                    -subj   "/C=FR/L=PARIS/O=42/OU=${NGINX_USER}/CN=${NGINX_URL_HOST}"   \
                    -out    /etc/nginx/ssl/inception.crt                        \
                    -keyout /etc/nginx/ssl/inception.key                        \
                    > /dev/null

    usermod     -d /var/www/public www-data

    sed         -i "s|\${NGINX_URL_HOST}|${NGINX_URL_HOST}|g" /etc/nginx/nginx.conf
    sed         -i "s|\${NGINX_BASE}|${NGINX_BASE}|g" /etc/nginx/nginx.conf
    sed         -i "s|\${WDP_DOCKER_HOST}|${WDP_DOCKER_HOST}|g" /etc/nginx/nginx.conf
    sed         -i "s|\${WDP_DOCKER_PORT}|${WDP_DOCKER_PORT}|g" /etc/nginx/nginx.conf

fi

# BOOT #########################################

nginx -g "daemon off;"

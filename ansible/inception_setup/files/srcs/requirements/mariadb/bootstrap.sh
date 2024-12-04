#!/bin/sh

# INITIALIZATION ###############################

if [ ! -f "/build/.init" ] || [ "$(< "/build/.init")" != "1" ]
then

    sleep       1 && echo 1 > /build/.init

    mysql_install_db --skip-test-db --user=root > /dev/null

    echo        >> /build/tmp "FLUSH PRIVILEGES;"
    echo        >> /build/tmp "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"

    echo        >> /build/tmp "CREATE DATABASE IF NOT EXISTS ${SQL_DATABASE} CHARACTER SET ${SQL_CHARSET} COLLATE ${SQL_COLLATE};"
    echo        >> /build/tmp "GRANT ALL PRIVILEGES ON ${SQL_DATABASE}.* TO '${SQL_USER_LOGIN}'@'%' IDENTIFIED BY '${SQL_USER_PASSWORD}';"

    mysqld      --bootstrap < /build/tmp
    rm          -rf /build/tmp

fi

# BOOT #########################################

mysqld --user=root

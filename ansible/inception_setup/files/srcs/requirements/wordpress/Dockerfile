# OPERATING ####################################

FROM        debian:12

# CONFIGURATION ################################

ARG         CONTAINER_PKG="curl php8.2 php8.2-cgi php8.2-fpm php8.2-mysqli php8.2-curl php8.2-dom php8.2-exif php8.2-mbstring php8.2-xml php8.2-redis"
ARG         CONTAINER_DIR="run/php:777 var/www/public:755:www-data"
ARG         CONTAINER_CFG="var/www/wp-config.php"
EXPOSE      9000

# INSTALLATION #################################

RUN         apt -y update && apt -y install ${CONTAINER_PKG}
RUN         apt clean && rm -rf /var/lib/apt/lists/*

RUN         mkdir -p /build
COPY        con[f]/ /build/conf/

RUN         for _d in ${CONTAINER_DIR}; do                          \
                _p=$(echo ${_d} | cut -d ':' -f 1);                 \
                _m=$(echo ${_d} | cut -d ':' -f 2);                 \
                _o=$(echo ${_d} | cut -d ':' -f 3);                 \
                rm -rf /${_p} && mkdir -p /${_p} -m ${_m};          \
                if [ ${_o} ]; then chown ${_o}:${_o} /${_p}; fi;    \
            done

RUN         for _d in ${CONTAINER_CFG}; do                          \
                mkdir -p /$(dirname ${_d});                         \
                mv -f /build/conf/$(basename ${_d}) /${_d};         \
            done

# BOOTSTRAP ####################################

COPY        bootstrap.sh /
ENTRYPOINT	["sh", "bootstrap.sh"]

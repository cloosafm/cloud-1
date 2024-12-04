# OPERATING ####################################

FROM        debian:12

# CONFIGURATION ################################

ARG         CONTAINER_PKG="mariadb-server"
ARG         CONTAINER_DIR="run/mysqld:755 var/lib/mysql:700:mysql var/run/mysql:700:mysql"
ARG         CONTAINER_CFG="etc/mysql/my.cnf"
EXPOSE      3306

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

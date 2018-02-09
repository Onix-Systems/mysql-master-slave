#!/bin/bash

set -e

MAX_WAIT_TIMEOUT=30

[ -z "${MASTER_DB_HOST}" ] && MASTER_DB_HOST=master
[ -z "${MYSQL_ROOT_USER}" ] && MYSQL_ROOT_USER=root
[ -z "${MYSQL_ROOT_PASSWORD}" ] && MYSQL_ROOT_PASSWORD=empty

if [ -z "${SLAVE_USER}" ] || [ -z "${SLAVE_USER_PASSWORD}" ]; then
    echo "Not enough input parametrs."
    exit 1
fi

printf "Waiting for master DB will be ready"
IS_READY=false
I=0
set +e
while [ $IS_READY == false ]; do
    nc -z -w 1 ${MASTER_DB_HOST} 3306
    [ $? == 0 ] && IS_READY=true
    printf "."
    sleep 1
    let I=${I}+1
    if [ ${I} -eq ${MAX_WAIT_TIMEOUT} ]; then
        echo
        echo "Max wait timeout of waiting for MySQL ready state was exceeded."
        exit 1
    fi
done
sleep 5
echo " Ready."
set -e

echo "Preparing master db host to be connected by slave replica."
export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}
mysql -sN -uroot -h${MASTER_DB_HOST} -e "
    GRANT REPLICATION SLAVE ON *.* TO '${SLAVE_USER}'@'%' IDENTIFIED BY '${SLAVE_USER_PASSWORD}';
    FLUSH PRIVILEGES;
    USE ${MYSQL_DATABASE};
    FLUSH TABLES WITH READ LOCK;
"
STATUS=$(mysql -sN -uroot -h${MASTER_DB_HOST} -e "SHOW MASTER STATUS;")
LOG_FILE=$(echo ${STATUS} | cut -f1 -d " ")
POSITION=$(echo ${STATUS} | cut -f2 -d " ")

echo "${LOG_FILE} / ${POSITION}"

printf "Downloading database dump. "
mysqldump -uroot -h${MASTER_DB_HOST} ${MYSQL_DATABASE} > /tmp/${MYSQL_DATABASE}.sql
echo "Done."

mysql -uroot -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "UNLOCK TABLES; SHOW MASTER STATUS;"

# Working on slave node
mysql -uroot ${MYSQL_DATABASE} < /tmp/${MYSQL_DATABASE}.sql
mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='${MASTER_DB_HOST}',MASTER_USER='${SLAVE_USER}', MASTER_PASSWORD='${SLAVE_USER_PASSWORD}', MASTER_LOG_FILE='${LOG_FILE}', MASTER_LOG_POS=${POSITION};"

if [ -z "${CONFIG_FILE_TEMPLATE}" ] || [ -z "${CONFIG_FILE}" ]; then
    echo "Not enough input parameters."
    exit 1
fi

if [ ! -f "${CONFIG_FILE_TEMPLATE}" ]; then
    echo "Could not be found template for custom config."
    exit 1
fi

# Genereting unique ID for current instance
export SERVER_ID=$(cat /proc/sys/kernel/random/uuid | tr -dc '1-9' | cut -c1-8)
echo "Current SERVER_ID is: ${SERVER_ID}"
#
printf "Generating custom config from template. "
cat ${CONFIG_FILE_TEMPLATE} | envsubst > ${CONFIG_FILE}
echo "Done."

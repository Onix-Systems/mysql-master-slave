#!/bin/bash

set -e

[ -z "${MASTER_DB_HOST}" ] && MASTER_DB_HOST=master
MASTER_DB_PORT=3306
[ -z "${MYSQL_ROOT_USER}" ] && MYSQL_ROOT_USER=root
[ -z "${MYSQL_ROOT_PASSWORD}" ] && MYSQL_ROOT_PASSWORD=empty

if [ -z "${SLAVE_USER}" ] || [ -z "${SLAVE_USER_PASSWORD}" ]; then
    echo "Not enough input parametrs."
    exit 1
fi

printf "Waiting for master DB will be ready."
IS_READY=false
while [ $IS_READY == false ]; do
    sleep 10
    nc -z -w 1 ${MASTER_DB_HOST} ${MASTER_DB_PORT}
    [ $? == 0 ] && IS_READY=true
done
echo

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

printf "Downloading database dump. "
mysqldump -uroot -h${MASTER_DB_HOST} ${MYSQL_DATABASE} > /tmp/${MYSQL_DATABASE}.sql
echo "Done."

mysql -uroot -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "UNLOCK TABLES; SHOW MASTER STATUS;"

# Working on slave node
mysql -uroot -hlocalhost ${MYSQL_DATABASE} < /tmp/${MYSQL_DATABASE}.sql

mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='${MASTER_DB_HOST}',MASTER_USER='${SLAVE_USER}', MASTER_PASSWORD='${SLAVE_USER_PASSWORD}', MASTER_LOG_FILE='${LOG_FILE}', MASTER_LOG_POS=${POSITION};"

if [ -z "${CUSTOM_CONF_TEMPLATE}" ] || [ -z "${CUSTOM_CONF}" ]; then
    echo "Not enough input parameters."
    exit 1
fi

if [ ! -e "${CUSTOM_CONF_TEMPLATE}" ]; then
    echo "Could not be found template for custom config."
    exit 1
fi

printf "Generating custom config from template. "
cat ${CUSTOM_CONF_TEMPLATE} | envsubst > ${CUSTOM_CONF}
echo "Done."

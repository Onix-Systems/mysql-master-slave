#!/bin/bash

set -e

[ -z "${MASTER_DB_HOST}" ] && MASTER_DB_HOST=master
[ -z "${MYSQL_ROOT_USER}" ] && MYSQL_ROOT_USER=root
[ -z "${MYSQL_ROOT_PASSWORD}" ] && MYSQL_ROOT_PASSWORD=empty

if [ -z "${SLAVE_USER}" ] || [ -z "${SLAVE_USER_PASSWORD}" ]; then
    echo "Not enough input parametrs."
    exit 1
fi

echo "Preparing master db host to be connected by slave replica."
export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}
mysql -sN -uroot -hmaster -e "
    GRANT REPLICATION SLAVE ON *.* TO '${SLAVE_USER}'@'%' IDENTIFIED BY '${SLAVE_USER_PASSWORD}';
    FLUSH PRIVILEGES;
"

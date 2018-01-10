#!/bin/bash

set -e

[ -z "${MASTER_DATA_FOLDER}" ] && MASTER_DATA_FOLDER=/data/master
[ -z "${SLAVE_DATA_FOLDER}" ] && MASTER_DATA_FOLDER=/data/slave
[ -z "${MYSQL_USER}" ] && MYSQL_USER=mysql

MYSQL_USER_ID=$(id -u ${MYSQL_USER})
MYSQL_GROUP_ID=$(id -g ${MYSQL_USER})

printf "Checking rights for master data folder. "
if [ "$(stat -c %u:%g ${MASTER_DATA_FOLDER})" != "${MYSQL_USER_ID}:${MYSQL_GROUP_ID}" ]; then
    chown -R ${MYSQL_USER_ID}:${MYSQL_GROUP_ID} ${MASTER_DATA_FOLDER}
    echo "Done."
else
    echo "No changes."
fi
echo

printf "Checking rights for slave data folder. "
if [ "$(stat -c %u:%g ${SLAVE_DATA_FOLDER})" != "${MYSQL_USER_ID}:${MYSQL_GROUP_ID}" ]; then
    chown -R ${MYSQL_USER_ID}:${MYSQL_GROUP_ID} ${SLAVE_DATA_FOLDER}
    echo "Done."
else
    echo "No changes."
fi
echo

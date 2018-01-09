#!/bin/bash

[ -z "${DATA_FOLDER}" ] && DATA_FOLDER=/data
[ -z "${MYSQL_USER}" ] && MYSQL_USER=mysql

MYSQL_USER_ID=$(id -u ${MYSQL_USER})
MYSQL_GROUP_ID=$(id -g ${MYSQL_USER})

printf "Checking rights for data folder. "
if [ "$(stat -c %u:%g ${DATA_FOLDER})" != "${MYSQL_USER_ID}:${MYSQL_GROUP_ID}" ]; then
    chown -R ${MYSQL_USER_ID}:${MYSQL_GROUP_ID} ${DATA_FOLDER}
    echo "Done."
else
    echo "No changes."
fi
echo

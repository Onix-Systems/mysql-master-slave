#!/bin/bash

CONFIG_FILE=${HOME}/.my.cnf

if [ ! -z "MYSQL_ROOT_PASSWORD" ] && [ ! -e "${CONFIG_FILE}" ]; then
    echo "Creating ${HOME}/.my.cnf file..."
    cat << EOF > ${CONFIG_FILE}
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
fi

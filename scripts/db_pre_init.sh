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

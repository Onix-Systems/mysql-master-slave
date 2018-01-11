#!/bin/bash -e

#
# Entrypoint for running ProxySQL service
#

if [ ! -f "${CONFIG_FILE_TEMPLATE}" ]; then
    echo "Config file template could not be found! Please check."
    exit 1
fi

printf "Generating custom config from template. "
if [ ! -e "${CONFIG_FILE}.lock" ]; then
    cat ${CONFIG_FILE_TEMPLATE} | envsubst > ${CONFIG_FILE}
    touch ${CONFIG_FILE}.lock
    echo "Done."
else
    echo "Skipped. Config file is already generated."
    echo "For recreating config file from template, please recreate the container."
fi

exec $@

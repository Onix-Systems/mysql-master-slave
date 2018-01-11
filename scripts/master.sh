#!/bin/bash

set -e

if [ -z "${CONFIG_TEMPLATE}" ] || [ -z "${CONFIG_FILE}" ]; then
    echo "Not enough input parameters."
    exit 1
fi

if [ ! -e "${CONFIG_TEMPLATE}" ]; then
    echo "Could not be found template for custom config."
    exit 1
fi

printf "Generating custom config from template. "
cat ${CONFIG_TEMPLATE} | envsubst > ${CONFIG_FILE}
echo "Done."

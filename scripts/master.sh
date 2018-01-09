#!/bin/bash

set -e

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

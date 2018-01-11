#!/bin/bash -e

#
# Entrypoint for running ProxySQL service
#

if [ ! -f "${CONFIG_FILE_TEMPLATE}" ]; then
    echo "Config file template could not be found! Please check."
    exit 1
fi

printf "Generating custom config from template. "
cat ${CONFIG_TEMPLATE} | envsubst > ${CONFIG_FILE}
echo "Done."

exec $@

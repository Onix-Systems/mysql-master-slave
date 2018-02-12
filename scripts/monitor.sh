#!/bin/bash -e

echo "Creating monitor user for proxysql"

export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}

#
# TODO: Clarify more correct rights for monitor user
#

if [ -z "${MONITOR_USERNAME}" ] || [ -z "${MONITOR_PASSWORD}" ]; then
    echo "MONITOR_USERNAME and MONITOR_PASSWORD must be defined. Please check."
    exit 1
fi

mysql -uroot -e "
    CREATE USER '${MONITOR_USERNAME}'@'%' IDENTIFIED BY '${MONITOR_PASSWORD}';
    GRANT ALL ON *.* TO '${MONITOR_USERNAME}'@'%';
"

#!/bin/bash

echo "Creating monitor user for proxysql"

export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}

#
# TODO: Clarify more correct rights for monitor user
#

mysql -uroot -e "
    CREATE USER '${MONITOR_USERNAME}'@'%' IDENTIFIED BY '${MONITOR_PASSWORD}';
    GRANT ALL ON *.* TO '${MONITOR_USERNAME}'@'%';
"

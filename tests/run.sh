#!/bin/bash

MAX_WAIT_TIMEOUT=120
SOURCE_FOLDER=/bash_unit

cd $(dirname $0)

SLAVE_DB_HOST=${SLAVE_DB_HOST:-localhost}

printf "Waiting for MySQL on ${SLAVE_DB_HOST} will be ready"
IS_READY=false
I=0
set +e
while [ $IS_READY == false ]; do
    nc -z -w 1 ${SLAVE_DB_HOST} 3306
    [ $? == 0 ] && IS_READY=true
    printf "."
    sleep 1
    let I=${I}+1
    if [ ${I} -eq ${MAX_WAIT_TIMEOUT} ]; then
        echo
        echo "Max wait timeout of waiting for MySQL ready state was exceeded."
        exit 1
    fi
done
sleep 5
echo " Ready for testing."
set -e

echo "Checking all requirements for running tests against this project."

if [ "$(which git)" == "" ]; then
    apt-get update &> /dev/null
    apt-get install -y git &> /dev/null
fi

if [ "$(which bash_unit)" == "" ]; then
mkdir -p ${SOURCE_FOLDER}
git clone https://github.com/pgrange/bash_unit.git ${SOURCE_FOLDER} &> /dev/null
ln -s ${SOURCE_FOLDER}/bash_unit /usr/sbin/bash_unit
fi

echo
bash_unit tests.sh

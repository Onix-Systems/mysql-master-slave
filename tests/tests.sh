#!/bin/bash

printf "Checking environment. "
if [ "$(basename $0)" != "bash_unit" ]; then
    echo
    echo "This scripts must be launched inside the bash_unit tool only."
    exit 1
fi
echo "Done."

if [ -z "${MYSQL_ROOT_PASSWORD}" ] || [ -z "${MYSQL_DATABASE}" ] || [ -z "${MASTER_DB_HOST}" ]; then
    echo "Not enough input parameters."
    exit 1
fi

export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}
MYSQL_TEST_TABLE=test_table
SLAVE_DB_HOST=localhost
DEFAULT_TIMEOUT=1

CREATE_TABLE_QUERY="
  CREATE TABLE IF NOT EXISTS \`${MYSQL_TEST_TABLE}\` (
      id INT NOT NULL AUTO_INCREMENT,
      message VARCHAR(100),
      PRIMARY KEY (id)
  );
"

test_00_replication_create_table() {
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "${CREATE_TABLE_QUERY}")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on creating test table on master host."
    sleep ${DEFAULT_TIMEOUT}
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SHOW TABLES LIKE '${MYSQL_TEST_TABLE}'")
    RTRN=$?
    assert_equals "${MYSQL_TEST_TABLE}" "${STDOUT}" "Can not be found ${MYSQL_TEST_TABLE} on slave."
}

test_01_replication_insert() {
    MESSAGE_VALUE=$(date)
    INSERT_QUERY="INSERT INTO ${MYSQL_TEST_TABLE} (message) VALUES ('${MESSAGE_VALUE}');"
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "${INSERT_QUERY}")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on inserting test record into test table on master host."
    sleep ${DEFAULT_TIMEOUT}
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SELECT count(*) FROM ${MYSQL_TEST_TABLE} WHERE message='${MESSAGE_VALUE}';")
    RTRN=$?
    assert_equals "1" "${STDOUT}" "Value '${MESSAGE_VALUE}' can not be found on slave."
}

test_02_replication_drop_table() {
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "DROP TABLE \`${MYSQL_TEST_TABLE}\`;")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error while deleting test table on master host."
    sleep 1
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SHOW TABLES LIKE '${MYSQL_TEST_TABLE}'")
    RTRN=$?
    assert_equals "" "${STDOUT}" "Table ${MYSQL_TEST_TABLE} is still present on slave."
}

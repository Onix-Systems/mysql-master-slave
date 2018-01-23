#!/bin/bash

printf "Checking environment. "
if [ "$(basename $0)" != "bash_unit" ]; then
    echo
    echo "Error! This scripts must be launched inside the bash_unit tool only."
    exit 1
fi
echo "Done."

if [ -z "${MYSQL_ROOT_PASSWORD}" ] || [ -z "${MYSQL_DATABASE}" ] || [ -z "${MASTER_DB_HOST}" ] || [ -z "${SLAVE_DB_HOST}" ] ||
   [ -z "${PROXYSQL_DB_HOST}" ] || [ -z "${PROXYSQL_DB_PORT}" ] || [ -z "${MYSQL_USER}" ] || [ -z "${MYSQL_PASSWORD}" ]; then
    echo "Error! Not enough input parameters."
    exit 1
fi

export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}
MYSQL_TEST_TABLE=test_table
SLAVE_DB_HOST=${SLAVE_DB_HOST:-localhost}
DEFAULT_TIMEOUT=1
MAX_RETRY=10
CREATE_TABLE_QUERY="
  CREATE TABLE IF NOT EXISTS \`${MYSQL_TEST_TABLE}\` (
      id INT NOT NULL AUTO_INCREMENT,
      message VARCHAR(100),
      PRIMARY KEY (id)
  );
"

test_00_check_slave_status() {
    STDOUT=$(mysql -h${SLAVE_DB_HOST} -e "show slave status \G" | grep Slave_IO_Running | sed -r "s/ //g" | cut -d ":" -f 2)
    RTRN=$?
    assert_equals "Yes" ${STDOUT} "Error checking Slave_IO_Running option."
    STDOUT=$(mysql -h${SLAVE_DB_HOST} -e "show slave status \G" | grep Slave_SQL_Running | sed -r "s/ //g" | cut -d ":" -f 2)
    RTRN=$?
    assert_equals "Yes" ${STDOUT} "Error checking Slave_SQL_Running option."
}

test_01_replication_create_table() {
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "${CREATE_TABLE_QUERY}")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on creating test table on master host."
    sleep ${DEFAULT_TIMEOUT}
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SHOW TABLES LIKE '${MYSQL_TEST_TABLE}'")
    RTRN=$?
    assert_equals "${MYSQL_TEST_TABLE}" "${STDOUT}" "Can not be found ${MYSQL_TEST_TABLE} on slave."
}

test_02_replication_compare_tables_names() {
    MASTER_TABLES_LIST=$(mysql -sN -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "show tables;" | tr "\n" ",")
    SLAVE_TABLES_LIST=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "show tables;" | tr "\n" ",")
    assert_equals "${MASTER_TABLES_LIST}" "${SLAVE_TABLES_LIST}" "Lists of tables are not equal on master and slave servers."
}

test_03_replication_insert() {
    MESSAGE_VALUE=$(date)
    INSERT_QUERY="INSERT INTO ${MYSQL_TEST_TABLE} (message) VALUES ('${MESSAGE_VALUE}');"
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "${INSERT_QUERY}")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on inserting test record into test table on master host."
    I=0
    STDOUT="0"
    START=$(($(date +%s%N)/1000000))
    while [ ${STDOUT} -eq 0 ] && [ $I -le ${MAX_RETRY} ]; do
        STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SELECT count(*) FROM ${MYSQL_TEST_TABLE} WHERE message='${MESSAGE_VALUE}';")
        RTRN=$?
        let I=${I}+1
    done
    let REPLICATION_TIME=$(($(date +%s%N)/1000000))-${START}
    assert_equals "1" "${STDOUT}" "Value '${MESSAGE_VALUE}' can not be found on slave."
    printf "Attempts ${I}/${MAX_RETRY}. Was replicated in ${REPLICATION_TIME} miliseconds. "
}

test_04_proxysql_check_insert() {
    MESSAGE_VALUE="$(date +%s)"
    STDOUT=$(MYSQL_PWD=${MYSQL_PASSWORD} mysql -sN -h${PROXYSQL_DB_HOST} -P${PROXYSQL_DB_PORT} -u ${MYSQL_USER} ${MYSQL_DATABASE} -e "INSERT INTO ${MYSQL_TEST_TABLE} (message) VALUES ('${MESSAGE_VALUE}');")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on inserting test record into test table through the PROXYSQL service."
    sleep ${DEFAULT_TIMEOUT}
    STDOUT=$(mysql -sN -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "SELECT count(*) FROM ${MYSQL_TEST_TABLE} WHERE message='${MESSAGE_VALUE}';")
    RTRN=$?
    assert_equals "1" "${STDOUT}" "Value '${MESSAGE_VALUE}' can not be found on master."
    sleep ${DEFAULT_TIMEOUT}
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SELECT count(*) FROM ${MYSQL_TEST_TABLE} WHERE message='${MESSAGE_VALUE}';")
    RTRN=$?
    assert_equals "1" "${STDOUT}" "Value '${MESSAGE_VALUE}' can not be found on slave."
}

test_05_proxysql_check_select_balancing() {
    # Insert unique record into slave table only and try find it by using proxysql access point.
    # This function should find at least one match of the message value.
    RANDOM_RANGE=1000
    RANDOM_START=100
    MESSAGE_VALUE=$(date)
    RECORD_ID=$(( (RANDOM % ${RANDOM_RANGE}) + ${RANDOM_START} ))
    # Inserting value only to slave DB for further checking the select by proxysql
    STDOUT=$(MYSQL_PWD=${MYSQL_PASSWORD} mysql -sN -h${SLAVE_DB_HOST} -u ${MYSQL_USER} ${MYSQL_DATABASE} -e "INSERT INTO ${MYSQL_TEST_TABLE} (id,message) VALUES (${RECORD_ID}, '${MESSAGE_VALUE}');")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error on inserting test record into test table to slave DB directly."
    MAX_ATTEMPTS=10
    ATTEMPT=0
    MATCHED_COUNT=0
    for ATTEMPT in $(seq 1 ${MAX_ATTEMPTS}); do
        STDOUT=$(MYSQL_PWD=${MYSQL_PASSWORD} mysql -sN -h${PROXYSQL_DB_HOST} -P${PROXYSQL_DB_PORT} -u${MYSQL_USER} ${MYSQL_DATABASE} -e "SELECT message FROM ${MYSQL_TEST_TABLE} WHERE id='${RECORD_ID}';")
        RTRN=$?
        if [ "${STDOUT}" == "${MESSAGE_VALUE}" ]; then let MATCHED_COUNT=${MATCHED_COUNT}+1; fi
    done
    printf "Was matched ${MATCHED_COUNT}/${MAX_ATTEMPTS} times. "
    test ${MATCHED_COUNT} -ge 1
    assert_equals "0" "$?" "Matched count is not enough."
}

test_06_replication_drop_table() {
    STDOUT=$(mysql -h${MASTER_DB_HOST} ${MYSQL_DATABASE} -e "DROP TABLE \`${MYSQL_TEST_TABLE}\`;")
    RTRN=$?
    assert_equals 0 ${RTRN} "Error while deleting test table on master host."
    sleep 1
    STDOUT=$(mysql -sN -h${SLAVE_DB_HOST} ${MYSQL_DATABASE} -e "SHOW TABLES LIKE '${MYSQL_TEST_TABLE}'")
    RTRN=$?
    assert_equals "" "${STDOUT}" "Table ${MYSQL_TEST_TABLE} is still present on slave."
}

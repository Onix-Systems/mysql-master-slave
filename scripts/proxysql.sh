#!/bin/bash

#
# Entrypoint for running ProxySQL service
#

#
# TODO: Refactore proxysql.cnf to template and replace credentials from global env
#

exec $@

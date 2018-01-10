## MySQL master/slave example
[![Build Status](https://travis-ci.org/Onix-Systems/mysql-master-slave.svg?branch=master)](https://travis-ci.org/Onix-Systems/mysql-master-slave)

### Requirements

1. docker-engine
1. docker-compose (support version: 3)

### Usage
```
$ docker-compose build
$ docker-compose up -d
$ docker-compose ps
Name                          Command               State           Ports         
---------------------------------------------------------------------------------------------
mysqlhighload_configurator_1   docker-entrypoint.sh /conf ...   Exit 0                        
mysqlhighload_master_1         docker-entrypoint.sh --cha ...   Up       3306/tcp             
mysqlhighload_phpmyadmin_1     /run.sh phpmyadmin               Up       0.0.0.0:8080->80/tcp
mysqlhighload_slave_1          docker-entrypoint.sh --cha ...   Up       3306/tcp             
```

After successfully deployment, user can open phpmyadmin to check connectivity
with master and slave MySQL servers.

phpmyadmin is accessible by url: http://localhost:8080/

### Running tests

To launch unit tests for testing MySQL master/slave configuration, please execute:

```
$ docker-compose exec slave /tests/run.sh
```

Tests items:

* Creating test table on master servers
* Instert new record in previously created table
* Drop table on master server

All these actions sequentally will be checked on slave server in 1 second after execution.

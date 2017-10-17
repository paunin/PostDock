# PostDock - Postgres + Docker

Postgres streaming replication cluster for any docker environment (Kubernetes, Docker Compose, Docker Swarm, Apache Mesos)

<img align="right" width="400" src="https://github.com/paunin/PostDock/blob/master/artwork/logo.png?raw=true">

- [Info](#info)
  * [Publications](#publications)
  * [What's in the box](#what-s-in-the-box)
  * [Docker images tags convention](#docker-images-tags-convention)
- [Schema of the example cluster](#schema-of-the-example-cluster)
- [Start cluster with docker-compose](#start-cluster-with-docker-compose)
- [Start cluster in Kubernetes](#start-cluster-in-kubernetes)
- [Adaptive mode](#adaptive-mode)
- [SSH access](#ssh-access)
- [Replication slots](#replication-slots)
- [Configuring the cluster](#configuring-the-cluster)
  * [Postgres](#postgres)
  * [Pgpool](#pgpool)
  * [Barman](#barman)
  * [Other configurations](#other-configurations)
- [Backups and recovery](#backups-and-recovery)
- [Health-checks](#health-checks)
- [Useful commands](#useful-commands)
- [Scenarios](#scenarios)
- [FAQ](#faq)
- [Documentation and manuals](#documentation-and-manuals)

-------

## Info

### Publications
* [Article on Medium.com](https://medium.com/@dpaunin/postgresql-cluster-into-kubernetes-cluster-f353cde212de)
* [Статья на habr-e](https://habrahabr.ru/post/301370/)

### What's in the box
[This project](https://github.com/paunin/postgres-docker-cluster) includes:
* Dockerfiles for `postgresql` cluster
    * [postgresql](./Postgres-latest.Dockerfile)
    * [pgpool](./Pgpool-latest.Dockerfile)
* Examples of usage(suitable for production environment as architecture has fault protection with auto failover)
    * example of [docker-compose](./docker-compose.yml) file to start this cluster.
    * directory [k8s](./k8s) contains information for building this cluster in Kubernetes

### Docker images tags convention

Taking into account that PostDock project itself has versioning schema, all docker images produced by the repository have schema - `postdock/<component>:<postdock_version>-<component><component_version>`, where:

* `<component>` - can be one of the value from the set `postgres`, `pgpool`, `barman`
* `<postdock_version>` - semantic version(without `bug-fix` component)
* `<component_version>` - depends on component:
    * `postgres` - major and minor version without dot in between(can be `95`,`96`,`100`,101)
    * `pgpool` - major and minor version without dot in between(can be `33`,`36`)
    * `barman` - major version (can be `2`,`3`)

Aliases are available:

* `postdock/<component>:latest-<component><component_version>` - refers to the latest release of the postdock and certain version of the component
* `postdock/<component>:latest` - refers to the latest release of the postdock and the component

**There is no alias for `master` branch build**


## Schema of the example cluster

```
pgmaster (primary node1)  --|
|- pgslave1 (node2)       --|
|  |- pgslave2 (node3)    --|----pgpool (master_slave_mode stream)
|- pgslave3 (node4)       --|
   |- pgslave4 (node5)    --|
```

Each `postgres` node (`pgmaster`, `pgslaveX`) is managed by `repmgr/repmgrd`. It allows to use automatic `failover` and check cluster status.


## Start cluster with docker-compose

To start cluster run it as normal `docker-compose` application `docker-compose up -d`

Please check comments for each `ENV` variable in [docker-compose.yml](./docker-compose.yml) file to understand parameter for each cluster node


## Start cluster in Kubernetes

To make it easier repository contains services' objects under `k8s` dir.
Setup `PostgreSQL` cluster following the steps in [the example](./k8s/example1/README.md)
It also has information how to check cluster state, so you will be able to see something like this:

From any DB node pod:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|---------------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replica_user password=replica_pass host=mysystem-db-node1-service dbname=replica_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replica_user password=replica_pass host=mysystem-db-node4-service dbname=replica_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replica_user password=replica_pass host=mysystem-db-node2-service dbname=replica_db port=5432 connect_timeout=2
  standby | node3 | node2    | user=replica_user password=replica_pass host=mysystem-db-node3-service dbname=replica_db port=5432 connect_timeout=2
  standby | node5 | node4    | user=replica_user password=replica_pass host=mysystem-db-node5-service dbname=replica_db port=5432 connect_timeout=2
```

From any Pgpool pod:
```
 node_id |         hostname          | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay
---------+---------------------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | mysystem-db-node1-service | 5432 | up     | 0.200000  | primary | 0          | false             | 0
 1       | mysystem-db-node2-service | 5432 | up     | 0.200000  | standby | 0          | false             | 0
 2       | mysystem-db-node3-service | 5432 | up     | 0.200000  | standby | 0          | false             | 0
 3       | mysystem-db-node4-service | 5432 | up     | 0.200000  | standby | 0          | false             | 0
 4       | mysystem-db-node5-service | 5432 | up     | 0.200000  | standby | 0          | true              | 0
(5 rows)

```

## Configuring the cluster

You can configure any node of the cluster(`postgres.conf`) or pgpool(`pgpool.conf`) with ENV variable `CONFIGS` (format: `variable1:value1[,variable2:value2[,...]]`). Also see the Dockerfiles and [docker-compose.yml](./docker-compose.yml) files in the root of the repository to understand all available and used configurations!

### Postgres

For the rest - you better **follow** the advise and look into the [Postgres-latest.Dockerfile](./Postgres-latest.Dockerfile) file - it full of comments :)

### Pgpool

The most important part to configure in Pgpool (apart of general `CONFIGS`) is backends and users which could access these backends. You can configure backends with ENV variable. You can find good example of setting up pgpool in [docker-compose.yml](./docker-compose.yml) file:

```
DB_USERS: monkey_user:monkey_pass # in format user:password[,user:password[...]]
BACKENDS: "0:pgmaster:5432:1:/var/lib/postgresql/data:ALLOW_TO_FAILOVER,1:pgslave1::::,3:pgslave3::::,2:pgslave2::::" #,4:pgslaveDOES_NOT_EXIST::::
            # in format num:host:port:weight:data_directory:flag[,...]
            # defaults:
            #   port: 5432
            #   weight: 1
            #   data_directory: /var/lib/postgresql/data
            #   flag: ALLOW_TO_FAILOVER
REQUIRE_MIN_BACKENDS: 3 # minimal number of backends to start pgpool (some might be unreachable)
```

### Barman

The most important part for barman is to setup access variables. Example can be found in [docker-compose.yml](./docker-compose.yml) file:

```
REPLICATION_USER: replication_user # default is replication_user
REPLICATION_PASSWORD: replication_pass # default is replication_pass
REPLICATION_HOST: pgmaster
POSTGRES_PASSWORD: monkey_pass
POSTGRES_USER: monkey_user
POSTGRES_DB: monkey_db
```

### Other configurations

**See the Dockerfiles and [docker-compose.yml](./docker-compose.yml) files in the root of the repository to understand all available and used configurations!**


## Adaptive mode

'Adaptive mode' means that node will be able to decide if instead of acting as a master on it's start or switch to standby role.
That possible if you pass `PARTNER_NODES` (comma separated list of nodes in the cluster on the same level).
So every time container starts it will check if it was master before and if there is no new master around (from the list `PARTNER_NODES`),
otherwise it will start as a new standby node with `upstream = new master` in the cluster.

Keep in mind: this feature does not work for cascade replication and you should not pass `PARTNER_NODES` to nodes on second level of the cluster.
Instead of it just make sure that all nodes on the first level are running, so after restart any node from second level will be able to follow initial upstream from the first level.
That also can mean - replication from second level potentially can connect to root master... Well not a big deal if you've decided to go with adaptive mode.
But nevertheless you are able to play with `NODE_PRIORITY` environment variable and make sure entry point for second level of replication will never be elected as a new root master 


## SSH access

If you have need to organize your cluster with some tricky logic or less problematic cross checks. You can enable SSH server on each node. Just set ENV variable `SSH_ENABLE=1` (disabled by default) in all containers (including pgpool and barman). That will allow you to connect from any to any node by simple command under `postgres` user: `gosu postgres ssh {NODE NETWORK NAME}`

You might want to change default ssh keys which are put into the cluster. For that you need to mount files with your keys in paths `/home/postgres/.ssh/id_rsa`, `/home/postgres/.ssh/id_rsa.pub`.


## Replication slots

If you want to disable the feature of Postgres>=9.4 - [replication slots](https://www.postgresql.org/docs/9.4/static/catalog-pg-replication-slots.html) simply set ENV variable `USE_REPLICATION_SLOTS=0` (enabled by default). So cluster will rely only on Postgres configuration `wal_keep_segments` (`500` by default). You also should remember that default number for configuration `max_replication_slots` is `5`. You can change it (as any other configuration) with ENV variable `CONFIGS`.


## Backups and recovery

[Barman](http://docs.pgbarman.org/) is used to provide real-time backups and Point In Time Recovery (PITR)..
This image requires connection information(host, port) and 2 sets of credentials, as you can see from [the Dockerfile](./Barman-latest.Dockerfile):

* Replication credentials
* Postgres admin credentials

Barman acts as warm standby and stream WAL from source. Additionaly it periodicaly takes remote physical backups using `pg_basebackup`.
This allows to make PITR in reasonable time within window of specified size, because you only have to replay WAL from lastest base backup.
Barman automatically deletes old backups and WAL according to retetion policy.
Backup source is static — pgmaster node.
In case of master failover, backuping will continue from standby server
Whole backup procedure is performed remotely, but for recovery SSH access is required.

*Before using in production read following documentation:*
 * http://docs.pgbarman.org/release/2.2/index.html
 * https://www.postgresql.org/docs/current/static/continuous-archiving.html

*For Disaster Recovery process see [RECOVERY.md](./RECOVERY.md)*


## Health-checks

To make sure you cluster works as expected without 'split-brain' or other issues, you have to setup health-checks and stop container if any health-check returns non-zero result.

* Postgres containers:
    * `/usr/local/bin/cluster/healthcheck/is_major_master.sh` - detect if node acts as a 'false'-master and there is another master - with more standbys
* Pgpool
    * `/usr/local/bin/pgpool/has_enough_backends.sh [REQUIRED_NUM_OF_BACKENDS, default=$REQUIRE_MIN_BACKENDS]` - check if there are enough backend behind `pgpool`
    * `/usr/local/bin/pgpool/has_write_node.sh` - check if one of the backend can be used as a master with write access

Abnormal but possible situation in cluster:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|---------------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replica_user password=replica_pass host=mysystem-db-node1-service dbname=replica_db port=5432 connect_timeout=2
  standby | node4 | node2    | user=replica_user password=replica_pass host=mysystem-db-node4-service dbname=replica_db port=5432 connect_timeout=2
* master  | node2 |          | user=replica_user password=replica_pass host=mysystem-db-node2-service dbname=replica_db port=5432 connect_timeout=2
  standby | node3 | node2    | user=replica_user password=replica_pass host=mysystem-db-node3-service dbname=replica_db port=5432 connect_timeout=2
  standby | node5 | node4    | user=replica_user password=replica_pass host=mysystem-db-node5-service dbname=replica_db port=5432 connect_timeout=2

```


## Useful commands

* Get map of current cluster(on any `postgres` node): 
    * `gosu postgres repmgr cluster show` - tries to connect to all nodes on request ignore status of node in `repmgr_$CLUSTER_NAME.repl_nodes`
    * `gosu postgres psql $REPLICATION_DB -c "SELECT * FROM repmgr_$CLUSTER_NAME.repl_nodes"` - just select data from tables
* Get `pgpool` status (on any `pgpool` node): `PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"`
* In `pgpool` container check if primary node exists: `/usr/local/bin/pgpool/has_write_node.sh` 

Any command might be wrapped with `docker-compose` or `kubectl` - `docker-compose exec {NODE} bash -c '{COMMAND}'` or `kubectl exec {POD_NAME} -- bash -c '{COMMAND}'`


## Scenarios

Check [the document](./FLOWS.md) to understand different cases of failover, split-brain resistance and recovery

## Tests

Check [the test directory](./tests/README.md) to understand how to run or create new tests

## FAQ

* Example of real/live usage: 
    * [Lazada/Alibaba Group](http://lazada.com/)
* Why not [sorintlab/stolon](https://github.com/sorintlab/stolon):
    * Complex logic with a lot of go-code
    * Non-standard tools for Postgres ecosystem
* [How to promote master, after failover on postgresql with docker](http://stackoverflow.com/questions/37710868/how-to-promote-master-after-failover-on-postgresql-with-docker)
* Killing of node in the middle (e.g. `pgslave1`) will cause [dieing of whole branch](https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)
   * That make seance as second or deeper level of replication should not be able to connect to root master (it makes extra load on server) or change upstream at all


## Documentation and manuals

* Streaming replication in postgres: https://wiki.postgresql.org/wiki/Streaming_Replication
* Repmgr: https://github.com/2ndQuadrant/repmgr
* Pgpool2: http://www.pgpool.net/docs/latest/pgpool-en.html
* Barman: http://www.pgbarman.org/
* Kubernetes: http://kubernetes.io/

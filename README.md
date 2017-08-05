# Streaming replication cluster for pgsql + pgpool2

## Info

### Publications
* [Article on Medium.com](https://medium.com/@dpaunin/postgresql-cluster-into-kubernetes-cluster-f353cde212de)
* [Статья на habr-e](https://habrahabr.ru/post/301370/)

### What's in the box
[This project](https://github.com/paunin/postgres-docker-cluster) includes:
* dockerfiles for `postgresql` cluster
    * [postgresql](./Postgres-latest.Dockerfile)
    * [pgpool](./Pgpool-latest.Dockerfile)
* Examples of usage(suitable for production environment as architecture has fault protection with auto failover)
    * example of [docker-compose](./docker-compose.yml) file to start this cluster.
    * directory [k8s](./k8s) contains information for building this cluster in kubernetes

### Artifacts

Two docker images were produced:
* Postgresql server image which can start in master or slave mode: https://hub.docker.com/r/paunin/postgresql-cluster-pgsql/
* Pgpool service with  flexible configurations: https://hub.docker.com/r/paunin/postgresql-cluster-pgpool/
* Barman - backup manager for postgres https://hub.docker.com/r/paunin/postgresql-cluster-barman/

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

Please check comments for each `ENV` variable in [docker-compose.yml](./docker-compose.yml) file to understand parameter for cluster's node

## Start cluster in Kubernetes

To make it easier repository contains services' objects under `k8s` dir
Setup `PostgreSQL` cluster folowing steps in [the example](./k8s/example1/README.md)
It has info how to check cluster state, so you will be able to see something like this:

From DB node:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|---------------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replica_user password=replica_pass host=mysystem-db-node1-service dbname=replica_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replica_user password=replica_pass host=mysystem-db-node4-service dbname=replica_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replica_user password=replica_pass host=mysystem-db-node2-service dbname=replica_db port=5432 connect_timeout=2
  standby | node3 | node2    | user=replica_user password=replica_pass host=mysystem-db-node3-service dbname=replica_db port=5432 connect_timeout=2
  standby | node5 | node4    | user=replica_user password=replica_pass host=mysystem-db-node5-service dbname=replica_db port=5432 connect_timeout=2
```
From Pgpool node:
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


## Adaptive mode

'Adaptive mode' means that node will be able to decide if instead of acting as a master on it's start or switch to standby role.
That possible if you pass `PARTNER_NODES` (comma separated list of nodes in the cluster on the same level).
So every time container starts it will check if it was master before and if there is no new master around (from the list `PARTNER_NODES`),
otherwise it will start as a new standby node with `upstream = new master` in the cluster.

Keep in mind: this feature does not work for cascade replication and you should not pass `PARTNER_NODES` to nodes on second level of the cluster.
Instead of it just make sure that all nodes on the first level are running, so after restart any node from second level will be able to follow initial upstream from the first level.
That also can mean - replication from second level potentially can connect to root master... Well not a big deal if you've decided to go with adaptive mode.
But nevertheless you are able to play with `NODE_PRIORITY` environment variable and make sure entry point for second level of replication will never be elected as a new root master 

## Backups and recovery

[Barman](http://docs.pgbarman.org/) is used to provide realtime backups using streaming of WAL files.
This image requires connection information(host, port) and 2 sets of credentials, as you can see from [the Dockerfile](./Barman-latest.Dockerfile):

* Replication credentials
* Postgres admin credentials

*Recovery process TBD*

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


## FAQ

* Example of real/live usage: 
    * [Lazada/Alibaba Group](http://lazada.com/)
* Why not [sorintlab/stolon](https://github.com/sorintlab/stolon):
    * Complex logic with a lot of go-code
    * Non-standard tools for Postgres ecosystem
* [How to promote master, after failover on postgresql with docker](http://stackoverflow.com/questions/37710868/how-to-promote-master-after-failover-on-postgresql-with-docker)
* Killing of node in the middle (e.g. `pgslave1`) will cause dieing of whole branch (https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)
   * That make seance as second or deeper level of replication should not be able to connect to root master (it makes extra load on server) or change upstream at all


## Documentation and manuals

* Streaming replication in postgres: https://wiki.postgresql.org/wiki/Streaming_Replication
* Repmgr: https://github.com/2ndQuadrant/repmgr
* Pgpool2: http://www.pgpool.net/docs/latest/pgpool-en.html
* Kubernetes: http://kubernetes.io/

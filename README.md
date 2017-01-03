# Streaming replication cluster for pgsql + pgpool2

## Info

### Publications
* [Article on Medium.com](https://medium.com/@dpaunin/postgresql-cluster-into-kubernetes-cluster-f353cde212de)
* [Статья на habr-e](https://habrahabr.ru/post/301370/)

### What's in the box
[This project](https://github.com/paunin/postgres-docker-cluster) includes:
* dockerfiles for `postgresql` cluster
    * [postgresql](./Pgsql.Dockerfile)
    * [pgpool](./Pgpool.Dockerfile)
* Examples of usage(suitable for production environment as architecture has fault protection with auto failover)
    * example of [docker-compose](./docker-compose.yml) file to start this cluster.
    * directory [k8s](./k8s) contains information for building this cluster in kubernetes

### Artifacts

Two docker images were produced:
* Postgresql server image which can start in master or slave mode: https://hub.docker.com/r/paunin/postgresql-cluster-pgsql/
* Pgpool service with  flexible configurations: https://hub.docker.com/r/paunin/postgresql-cluster-pgpool/

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

* Requires software: `minikube` (for local tests) and `kubectl`
* Using [minikube](https://github.com/kubernetes/minikube) you can start local Kubernetes cluster: `minikube start`, `minikube env`
* Setup `PostgreSQL` cluster: `kubectl create -f ./k8s/database-service/`
* Check everything works as expected
    * Proper DB operating:
      * Connect to any `postgres` node to be able to access DB (e.g. `docker-compose exec pgpool bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'`)
      * Do some read and write queries after connecting be command `PGPASSWORD=monkey_pass psql -U monkey_user -h database-pgpool-service -p 5432 monkey_db`
    * Check status/topology of the cluster (e.g. from master node) `gosu postgres repmgr cluster show`

Initial topology:
* Repmgr:
```
gosu postgres repmgr cluster show
[2016-12-28 06:46:13] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node3 | node2    | user=replication_user password=replication_pass host=pgslave2 dbname=replication_db port=5432 connect_timeout=2
  standby | node5 | node4    | user=replication_user password=replication_pass host=pgslave4 dbname=replication_db port=5432 connect_timeout=2
```

* Pgpool:
```
PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"
 node_id | hostname | port | status | lb_weight |  role   
---------+----------+------+--------+-----------+---------
 0       | pgmaster | 5432 | 2      | 0.250000  | primary
 1       | pgslave1 | 5432 | 2      | 0.250000  | standby
 2       | pgslave2 | 5432 | 2      | 0.250000  | standby
 3       | pgslave3 | 5432 | 2      | 0.250000  | standby
```

## Some rules of using cluster

### Docker compose restart
Don't try restart `docker-compose` without cleaning volumes after any failover (unless you use environment variable `FORCE_CLEAN=1` in each container)
You should update cluster with new topology manually because second start of initial master will bring inconsistent in the cluster.
Optionally you can reconfigure your pgpool to ignore initial master before second start

Abnormal but possible situation in cluster:
```
gosu postgres repmgr cluster show
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------
  standby | node3 | node2    | user=replication_user password=replication_pass host=pgslave2 dbname=replication_db port=5432
  standby | node5 | node4    | user=replication_user password=replication_pass host=pgslave4 dbname=replication_db port=5432
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432
* master  | node2 |          | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432
  standby | node4 | node2    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432
```

## Useful commands

* Get map of current cluster(on any `postgres` node): 
    * `gosu postgres repmgr cluster show` - tries to connect to all nodes on request ignore status of node in `repmgr_$CLUSTER_NAME.repl_nodes`
    * `gosu postgres psql $REPLICATION_DB -c "SELECT * FROM repmgr_$CLUSTER_NAME.repl_nodes"` - just select data from tables
* Get matrix of connections (on any `postgres` node) `gosu postgres repmgr cluster crosscheck`
* Get `pgpool` status (on any `pgpool` node): `PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"`
* In `pgpool` container check if primary node exists: `/usr/local/bin/pgpool/has_write_node.sh` 

Any command might be wrapped with `docker-compose` or `kubectl` - `docker-compose exec {NODE} bash -c '{COMMAND}'` or `kubectl exec {POD_NAME} -- bash -c '{COMMAND}'`

## Scenarios

Check [the document](./FLOWS.md) to understand different cases of failover, split-brain resistance and recovery

## Known problems

* Killing of node in the middle (e.g. `pgslave1`) will cause dieing of whole branch (https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)

## FAQ

* Example of real/live usage: 
    * [Lazada/Alibaba Group](http://lazada.com/)
* Why not [sorintlab/stolon](https://github.com/sorintlab/stolon):
    * Complex logic with a lot of go-code
    * Non-standard tools for Postgres ecosystem
* [How to promote master, after failover on postgresql with docker](http://stackoverflow.com/questions/37710868/how-to-promote-master-after-failover-on-postgresql-with-docker)

## Documentation and manuals

* Streaming replication in postgres: https://wiki.postgresql.org/wiki/Streaming_Replication
* Repmgr: https://github.com/2ndQuadrant/repmgr
* Pgpool2: http://www.pgpool.net/docs/latest/pgpool-en.html
* Kubernetes: http://kubernetes.io/

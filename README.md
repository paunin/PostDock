# Streaming replication cluster for pgsql + pgpool2

## Info
[Article on Medium.com](https://medium.com/@dpaunin/postgresql-cluster-into-kubernetes-cluster-f353cde212de)

[This project](https://github.com/paunin/postgres-docker-cluster) includes dockerfiles for postgresql cluster and example of [docker-compose](./docker-compose.yml) file to start this cluster.
Directory [k8s](./k8s) contains information for building this cluster in kubernetes

Also this example of cluster setup suitable for production environment as it has fault protection with auto failover system.

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

Each postgres node (pgmaster, pgslaveX) is managed by repmgr/repmgrd. It allows to use automatic failover and check cluster status.


## Strat cluster with docker-compose

To start cluster run it as normal docker-compose application `docker-compose up`

Please check comments for each ENV variable in [docker-compose.yml](./docker-compose.yml) file to understand related parameter of cluster's node

## Strat cluster in Kubernetes

To make it easier repository contains services' objects under `k8s` dir

* Requires software: `minikube` (for local tests) and `kubectl`
* Using [minikube](https://github.com/kubernetes/minikube) you can start local Kubernetes cluster: `minikube start`, `minikube env`
* Setup PostgreSQL cluster: `kubectl create -f ./k8s/database-service/`
* Check everything works as expected
    * Correct DB operating:
      * Connect to any `pgsql` node to be able to access DB 
      * Do some read and write queries after connecting be command `PGPASSWORD=monkey_pass psql -U monkey_user -h database-pgpool-service -p 5432 monkey_db`
    * Check status/topology of the cluster (e.g. from master node) `gosu postgres repmgr cluster show`

Initial topology:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=database-node1-service dbname=replication_db port=5432
  standby | node2 | node1    | user=replication_user password=replication_pass host=database-node2-service dbname=replication_db port=5432
  standby | node4 | node1    | user=replication_user password=replication_pass host=database-node4-service dbname=replication_db port=5432
  standby | node3 | node2    | user=replication_user password=replication_pass host=database-node3-service dbname=replication_db port=5432
  standby | node5 | node4    | user=replication_user password=replication_pass host=database-node5-service dbname=replication_db port=5432
```

## Some rules of using cluster

### Docker compose restart
Don't try restart `docker-compose` without cleaning volumes after any failover (unless you use environment variable `FORCE_CLEAN=1` in each container)
You should update cluster with new topology manually because second start of initial master will bring inconsistent in the cluster.
Optionally you can reconfigure your pgpool to ignore initial master before second start

Abnormal but possible situation in cluster:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------
  standby | node3 | node2    | user=replication_user password=replication_pass host=pgslave2 dbname=replication_db port=5432
  standby | node5 | node4    | user=replication_user password=replication_pass host=pgslave4 dbname=replication_db port=5432
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432
* master  | node2 |          | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432
  standby | node4 | node2    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432
```

## Useful commands

* Get map of current cluster(in any node): `gosu postgres repmgr cluster show`
* In `pgpool` container check if primary node exists: `/usr/local/bin/pgpool/has_write_node.sh`

## Scenarios

Check [the document](./FLOWS.md) to understand different cases of failover, split-brain resistance and recovery

## Known problems

* Killing of node in the middle (e.g. `pgslave1`) will cause dieing of whole branch (https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)

## FAQ

* [How to promote master, after failover on postgresql with docker](http://stackoverflow.com/questions/37710868/how-to-promote-master-after-failover-on-postgresql-with-docker)
* Example of real/live usage: 
    * [Lazada/Alibaba Group](http://lazada.com/)
* Why not [sorintlab/stolon](https://github.com/sorintlab/stolon):
    * Complex logic with a lot of go-code
    * Non-standard tools for Postgres ecosystem

## Documentation and manuals

* Streaming replication in postgres: https://wiki.postgresql.org/wiki/Streaming_Replication
* Repmgr: https://github.com/2ndQuadrant/repmgr
* Pgpool2: http://www.pgpool.net/docs/latest/pgpool-en.html
* Kubernetes: http://kubernetes.io/

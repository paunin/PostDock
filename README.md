# Streaming replication cluster for pgsql + pgpool2

[This project](https://github.com/paunin/postgres-docker-cluster) includes dockerfiles for postgresql cluster and example of [docker-compose](./docker-compose.yml) file to start this cluster.
Directory [k8s](./k8s) contains information for building this cluster in kubernetes

Also this example of cluster setup suitable for production environment as it has fault protection with auto failover system.

Two docker images were produced:
* Postgresql server image which can start in master or slave mode: https://hub.docker.com/r/paunin/postgresql-cluster-pgsql/
* Pgpool service with  flexible configurations: https://hub.docker.com/r/paunin/postgresql-cluster-pgpool/

## Schema of cluster

```
pgmaster (primary node1)  --|
|- pgslave1 (node2)       --|
|  |- pgslave2 (node3)    --|----pgpool (master_slave_mode stream)
|- pgslave3 (node4)       --|
   |- pgslave4 (node5)    --|
```

Each postgres node (pgmaster, pgslaveX) is managed by repmgr/repmgrd. It allows to use automatic failover and

To start cluster run it as normal docker-compose application `docker-compose up`

Please check comments for each ENV variable in [docker-compose](./docker-compose.yml) file to understand related parameter of cluster's node

## Strat cluster in Kubernetes

To make it easier repository contains scripts for starting cluster using docker-machine and services' objects under `k8s` dir
Requires software: `docker-machine` and `kubectl`

* Start k8s cluster by command `./k8s/scripts/cluster/up.sh` and wait until all pods up (to check it you acn use command `kubectl get pod --all-namespaces`)
Sometimes you can have problem with auto installation of DNS (after message `Unable to connect to the server: EOF`)
So do it manually with commands `docker-machine ssh $(docker-machine active) -N -L 8080:localhost:8080`(in separate terminal), `kubectl create namespace kube-system && kubectl create -f ./build/skydns.yaml`
* Start postgres cluster
    * If you have good fast machine and can relay on timeouts in configs `./k8s/scripts/up.sh` and check all pods are ready `kubectl get pod`
    * However you can install layers of the system one by one with checking pods' status:
        * Setup namespace and context of cluster: `./k8s/scripts/setup_context.sh && kubectl create ns app` (check namespace exists `kubectl get ns`)
        * Create master node `kubectl create -f ./k8s/database-service/node1-master.yaml`
        * Create first level of cluster `kubectl create -f ./k8s/database-service/node2.yaml && kubectl create -f ./k8s/database-service/node4.yaml` (node2 and node4 need around 4 minutes to start daemon)
        * Create second level of cluster `kubectl create -f ./k8s/database-service/node3.yaml && kubectl create -f ./k8s/database-service/node5.yaml` (node3 and node5 need around 6 minutes to start daemon)
        * Create pgpool endpoint `kubectl create -f ./k8s/database-service/pgpool.yaml` (need around 3 minutes to start service)
* Check everything works as expected
    * In each container you should see in logs 2 things:
        * Node registration success after line  `>>> Registering node with initial role master|standby`
        * Repmgr daemon started successfully after line `>>> Starting repmgr daemon...`
    * Connect to postgresql cluster endpoint and make some read and write queries: `PGPASSWORD=monkey_pass psql -Umonkey_user -h192.168.99.100 -p5430 monkey_db`
    * Check status/topology of the cluster (e.g. from master node) `docker exec -it "$(docker ps | grep 'postgresql-cluster-pgsql' | grep node1 | awk '{print $1}')" gosu postgres repmgr cluster show`

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

Topology after master death (`kubectl delete service database-node1-service`)
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|------------------------------------------------------------------------------------------------------------
  standby | node3 | node2    | user=replication_user password=replication_pass host=database-node3-service dbname=replication_db port=5432
  standby | node5 | node4    | user=replication_user password=replication_pass host=database-node5-service dbname=replication_db port=5432
  FAILED  | node1 |          | user=replication_user password=replication_pass host=database-node1-service dbname=replication_db port=5432
* master  | node2 |          | user=replication_user password=replication_pass host=database-node2-service dbname=replication_db port=5432
  standby | node4 | node2    | user=replication_user password=replication_pass host=database-node4-service dbname=replication_db port=5432
```

## Some rules of using cluster

### Docker compose restart
Don't try restart docker-compose without cleaning volumes after any failover (unless you use env variable FORCE_CLEAN=1 in each container)
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

### Time management in cluster
You should take care about delays of starts for different parts of the cluster.
Pgpool should be the last one to start, standbys servers should start after upstreams, etc
In docker-compose you can find example of `_DELAY`-s but it still can be wrong.
According your system and it's performance you should adjust those env variables.

## Useful commands

* Get map of current cluster(in any node): `gosu postgres repmgr cluster show`

## Scenarios

### Changing primary/master server on crash

Kill master container and in a few moments cluster will define new master node,
and Pgpool will try to detect new primary node for write access automatically.

## Improvements

Instead of one pgpool node you can have as many as you wish and balance load on them.
It's possible because pgpool does'not control cluster and does dummy balancing with primary server detection.


## Known problems

* Killing of node in the middle (e.g. pgslave1) will cause dieing of whole branch (https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)

## FAQ

* [How to promote master, after failover on postgresql with docker](http://stackoverflow.com/questions/37710868/how-to-promote-master-after-failover-on-postgresql-with-docker)

## Documentation and manuals

* Streaming replication in postgres: https://wiki.postgresql.org/wiki/Streaming_Replication
* Repmgr: https://github.com/2ndQuadrant/repmgr
* Pgpool2: http://www.pgpool.net/docs/latest/pgpool-en.html
* Kubernetes: http://kubernetes.io/

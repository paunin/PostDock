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

### Changing primary/master server on crash

* Start cluster `docker-compose up`
* Kill master container and in a few moments cluster will define new master node `docker-compose stop pgmaster`
* `pgpool` will try to detect new primary node for write access automatically.
Normal topology after master death:
```
Role      | Name  | Upstream | Connection String
----------+-------|----------|------------------------------------------------------------------------------------------------------------
  standby | node3 | node2    | user=replication_user password=replication_pass host=database-node3-service dbname=replication_db port=5432
  standby | node5 | node4    | user=replication_user password=replication_pass host=database-node5-service dbname=replication_db port=5432
  FAILED  | node1 |          | user=replication_user password=replication_pass host=database-node1-service dbname=replication_db port=5432
* master  | node2 |          | user=replication_user password=replication_pass host=database-node2-service dbname=replication_db port=5432
  standby | node4 | node2    | user=replication_user password=replication_pass host=database-node4-service dbname=replication_db port=5432
```

### Check split-brain in pgpool

The flow should proof that `pgpool` never has 2 primary nodes in the same moment.

* Start pgpool with 2 write nodes `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml up pgpool2` 
* See how pgpool reacts on two nodes with write access 
```
docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname  | port | status | lb_weight |  role   
---------+-----------+------+--------+-----------+---------
 0       | pgmaster  | 5432 | 2      | 0.500000  | primary
 1       | pgmaster2 | 5432 | 2      | 0.500000  | standby
(2 rows)
```
Basically first node with write access becomes primary
* Emulate broken connection to one node by command `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"`
* In a few moments you can check `pgpool`
```
docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname  | port | status | lb_weight |  role   
---------+-----------+------+--------+-----------+---------
 0       | pgmaster  | 5432 | 3      | 0.500000  | standby
 1       | pgmaster2 | 5432 | 2      | 0.500000  | primary
(2 rows)
```
* Provide connection to node again `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c "cat /etc/hosts | grep -v pgmaster > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"`
* And attach node back to the pool `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c "pcp_attach_node 10 localhost 9898 pcp_user pcp_pass 0"`
* Check `pgpool`, it should have initial node back as a primary node
```
docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname  | port | status | lb_weight |  role   
---------+-----------+------+--------+-----------+---------
 0       | pgmaster  | 5432 | 2      | 0.500000  | primary
 1       | pgmaster2 | 5432 | 2      | 0.500000  | standby
(2 rows)
```

### Check split-brain in cluster

The flow should proof that one (out of three) nodes will not be elected as master in case of lost connection to primary node

* Start cluster `docker-compose up -d`
* Drop useless nodes 
    * `docker-compose exec pgslave2 bash -c "gosu postgres repmgr standby unregister"`
    * `docker-compose exec pgslave4 bash -c "gosu postgres repmgr standby unregister"`
    * `docker-compose stop pgslave2 pgslave4`
* Cluster topology should look like:
```
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show"
[2016-12-27 17:07:21] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
```
* Emulate broken connection in one node(`node4` - `pgslave3`) by command `docker-compose exec pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts && echo 1.1.1.1 pgslave1 >> /etc/hosts"`
* See that isolated node dies in a few minutes:
```
docker-compose logs -f pgslave3
pgslave3_1  | [2016-12-27 17:13:45] [WARNING] connection to master has been lost, trying to recover... 10 seconds before failover decision
pgslave3_1  | [2016-12-27 17:13:52] [WARNING] connection to master has been lost, trying to recover... 5 seconds before failover decision
pgslave3_1  | [2016-12-27 17:13:59] [ERROR] unable to reconnect to master (timeout 20 seconds)...
pgslave3_1  | [2016-12-27 17:14:01] [ERROR] connection to database failed: timeout expired
pgslave3_1  | 
pgslave3_1  | [2016-12-27 17:14:11] [ERROR] connection to database failed: timeout expired
pgslave3_1  | 
pgslave3_1  | [2016-12-27 17:14:21] [ERROR] connection to database failed: timeout expired
pgslave3_1  | 
pgslave3_1  | [2016-12-27 17:14:21] [ERROR] Unable to reach most of the nodes.
pgslave3_1  | Let the other standby servers decide which one will be the master.
pgslave3_1  | Manual action will be needed to re-add this node to the cluster.
pgslave3_1  | [2016-12-27 17:14:21] [INFO] repmgrd terminating...
postgresdockercluster_pgslave3_1 exited with code 11
```
* The rest part of cluster should look like this:
```
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show"
[2016-12-27 17:22:04] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  FAILED  | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2

```
* `pgpool` should have 2 active nodes only:
```
docker-compose exec pgpool bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname | port | status | lb_weight |  role   
---------+----------+------+--------+-----------+---------
 0       | pgmaster | 5432 | 2      | 0.250000  | primary
 1       | pgslave1 | 5432 | 2      | 0.250000  | standby
 3       | pgslave3 | 5432 | 3      | 0.250000  | standby
```
* Bringing back lost slave will add it to cluster (but not to `pgpool`) - `docker-compose up pgslave3`
```
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show"
[2016-12-27 17:52:21] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
```

You can attach node to `pgpool` by command: `docker-compose exec pgpool bash -c 'pcp_attach_node 10 localhost 9898 $PCP_USER $PCP_PASSWORD 3'`
And check `pgpool`
```
docker-compose exec pgpool bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname | port | status | lb_weight |  role   
---------+----------+------+--------+-----------+---------
 0       | pgmaster | 5432 | 2      | 0.250000  | primary
 1       | pgslave1 | 5432 | 2      | 0.250000  | standby
 2       | pgslave2 | 5432 | 3      | 0.250000  | standby
 3       | pgslave3 | 5432 | 2      | 0.250000  | standby

```

## Known problems

* Killing of node in the middle (e.g. pgslave1) will cause dieing of whole branch (https://groups.google.com/forum/?hl=fil#!topic/repmgr/lPAYlawhL0o)

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

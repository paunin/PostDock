# Scenarios

Using only `docker-compose` utility we can run some scenarios to demonstrate the solution behaviour in different situations

## Master crash

* Start cluster `docker-compose up -d`
* Kill master container and in a few moments cluster will define new master node `docker-compose stop pgmaster`
* `pgpool` will try to detect new primary node for write access automatically.
* See topology after master death
    * Repmgr
```
docker-compose exec pgslave1 bash -c "gosu postgres repmgr cluster show"
[2016-12-28 07:10:53] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
  standby | node3 | node2    | user=replication_user password=replication_pass host=pgslave2 dbname=replication_db port=5432 connect_timeout=2
  standby | node5 | node4    | user=replication_user password=replication_pass host=pgslave4 dbname=replication_db port=5432 connect_timeout=2
  FAILED  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
* master  | node2 |          | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node2    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2

```
    * Pgpool
```
docker-compose exec pgpool bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname | port | status | lb_weight |  role   
---------+----------+------+--------+-----------+---------
 0       | pgmaster | 5432 | 3      | 0.250000  | standby
 1       | pgslave1 | 5432 | 2      | 0.250000  | primary
 2       | pgslave2 | 5432 | 2      | 0.250000  | standby
 3       | pgslave3 | 5432 | 2      | 0.250000  | standby
```

## Split-brain in pgpool with 2 write nodes

The flow should proof that `pgpool` never has 2 primary nodes in the same moment.

* Start pgpool with 2 write nodes `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml up -d pgpool2`
* See how pgpool reacts on two nodes with write access
```
docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname  | port | status | lb_weight |  role   
---------+-----------+------+--------+-----------+---------
 0       | pgmaster  | 5432 | 2      | 0.500000  | primary
 1       | pgmaster2 | 5432 | 2      | 0.500000  | standby
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
```
* Provide connection to node again `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c "cat /etc/hosts | grep -v pgmaster > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"`
* And attach node back to the pool `docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'pcp_attach_node -h localhost -U $PCP_USER -w 0'`
* Check `pgpool`, it should have initial node back as a primary node
```
docker-compose -f docker-compose.yml -f docker-compose/split-brain-pgpool.yml exec pgpool2 bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname  | port | status | lb_weight |  role   
---------+-----------+------+--------+-----------+---------
 0       | pgmaster  | 5432 | 2      | 0.500000  | primary
 1       | pgmaster2 | 5432 | 2      | 0.500000  | standby
```

## Split-brain (isolated standby)

The flow should proof that one (out of two) standby nodes will not be elected as master in case of lost connection to the rest of cluster

* Start cluster `docker-compose up -d`
* Drop useless nodes for the test
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
* Bringing back lost slave will add it to cluster (but not to `pgpool`) - `docker-compose up -d pgslave3`
```
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show"
[2016-12-27 17:52:21] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  standby | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
```

You can attach node to `pgpool` by command: `docker-compose exec pgpool bash -c 'pcp_attach_node -h localhost -U $PCP_USER -w 3'`
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

### Split-brain (isolated master)

[Test case](./tests/split-brain-isolated-master/setup.sh)

The flow should proof that in case of lost connection to master from standbys but not from pgpools:
* one of standby becomes master by election
* `pgpool` stop using old master and switch to the elected one

* Start cluster `docker-compose up -d`
* Drop useless nodes for the test
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
* Emulate broken connection from standbys to master(`node2` - `pgslave1`, `node4` - `pgslave3`) by commands
    * `docker-compose exec pgslave1 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"`
    * `docker-compose exec pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"`
    * `docker-compose exec pgmaster bash -c "echo 1.1.1.1 pgslave1 >> /etc/hosts && echo 1.1.1.1 pgslave3 >> /etc/hosts "`
* Make sure biggest part of your cluster has elected new master by command
on `node2` - `docker-compose exec pgslave1 bash -c "gosu postgres repmgr cluster show"` OR
on `node4` - `docker-compose exec pgslave3 bash -c "gosu postgres repmgr cluster show"`
```
[2016-12-28 03:16:33] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
  FAILED  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
* master  | node2 |          | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
  standby | node4 | node2    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
```
* In the same moment `pgmaster` initial primary node should still be alive but without standbys:
```
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show"
[2016-12-28 03:18:20] [INFO] connecting to database
Role      | Name  | Upstream | Connection String
----------+-------|----------|----------------------------------------------------------------------------------------------------------------
* master  | node1 |          | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
  FAILED  | node4 | node1    | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
  FAILED  | node2 | node1    | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
```
* Check `pgpool`
```
docker-compose exec pgpool bash -c 'PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"'
 node_id | hostname | port | status | lb_weight |  role   
---------+----------+------+--------+-----------+---------
 0       | pgmaster | 5432 | 2      | 0.250000  | primary
 1       | pgslave1 | 5432 | 2      | 0.250000  | standby
 3       | pgslave3 | 5432 | 2      | 0.250000  | standby

```

Use health-check in each node to check false-masters [`/usr/local/bin/cluster/healthcheck/is_major_master.sh`](./pgsql/bin/healthcheck/is_major_master.sh)

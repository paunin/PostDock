# Nodes table

## Repmgr 3

```
SELECT * FROM repmgr_tms_cluster.repl_nodes;
 id |  type   | upstream_node_id |   cluster   |  name   |                                                         conninfo                                                          |   slot_name   | priority | active
----+---------+------------------+-------------+---------+---------------------------------------------------------------------------------------------------------------------------+---------------+----------+--------
  4 | standby |                2 | tms_cluster | node-bi | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node-bi-service dbname=replica_db port=5432 connect_timeout=2 | repmgr_slot_4 |        0 | t
  2 | master  |                  | tms_cluster | node2   | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node2-service dbname=replica_db port=5432 connect_timeout=2   | repmgr_slot_2 |      100 | t
  3 | standby |                2 | tms_cluster | node3   | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node3-service dbname=replica_db port=5432 connect_timeout=2   | repmgr_slot_3 |      100 | t
  1 | standby |                2 | tms_cluster | node1   | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node1-service dbname=replica_db port=5432 connect_timeout=2   | repmgr_slot_1 |      100 | t
(4 rows)
```

## Repmgr 4

```
SELECT * FROM nodes;
 node_id | upstream_node_id | active | node_name |  type   | location | priority |                                                    conninfo                                                     |     repluser     |   slot_name   |   config_file
---------+------------------+--------+-----------+---------+----------+----------+-----------------------------------------------------------------------------------------------------------------+------------------+---------------+------------------
       1 |                  | t      | node1     | primary | default  |      100 | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2 | replication_user | repmgr_slot_1 | /etc/repmgr.conf
       4 |                1 | t      | node4     | standby | default  |      200 | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2 | replication_user | repmgr_slot_4 | /etc/repmgr.conf
       2 |                1 | t      | node2     | standby | default  |      100 | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2 | replication_user | repmgr_slot_2 | /etc/repmgr.conf
(3 rows)
```

# Show nodes table

## Repmgr 3

```
SELECT * FROM repmgr_tms_cluster.repl_show_nodes ;
 id |                                                         conninfo                                                          |  type   |  name   |   cluster   | priority | active | upstream_node_name
----+---------------------------------------------------------------------------------------------------------------------------+---------+---------+-------------+----------+--------+--------------------
  4 | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node-bi-service dbname=replica_db port=5432 connect_timeout=2 | standby | node-bi | tms_cluster |        0 | t      | node2
  2 | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node2-service dbname=replica_db port=5432 connect_timeout=2   | master  | node2   | tms_cluster |      100 | t      |
  3 | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node3-service dbname=replica_db port=5432 connect_timeout=2   | standby | node3   | tms_cluster |      100 | t      | node2
  1 | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node1-service dbname=replica_db port=5432 connect_timeout=2   | standby | node1   | tms_cluster |      100 | t      | node2
(4 rows)
```

## Repmgr 4

```
SELECT * FROM show_nodes;
 node_id | node_name | active | upstream_node_id | upstream_node_name |  type   | priority |                                                    conninfo
---------+-----------+--------+------------------+--------------------+---------+----------+-----------------------------------------------------------------------------------------------------------------
       1 | node1     | t      |                  |                    | primary |      100 | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
       4 | node4     | t      |                1 | node1              | standby |      200 | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
       2 | node2     | t      |                1 | node1              | standby |      100 | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
(3 rows)
```

# Cluster Show

## Repmg 3

```
gosu postgres repmgr cluster show
INFO: connecting to database
Role      | Name    | Upstream | Connection String
----------+---------|----------|--------------------------------------------------------------------------------------------------------------------------
  standby | node-bi | node2    | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node-bi-service dbname=replica_db port=5432 connect_timeout=2
* master  | node2   |          | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node2-service dbname=replica_db port=5432 connect_timeout=2
  standby | node3   | node2    | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node3-service dbname=replica_db port=5432 connect_timeout=2
  standby | node1   | node2    | user=replica_user password=replica_pass_55DhFu5 host=tms-db-node1-service dbname=replica_db port=5432 connect_timeout=2
```


## Repmg 4

```
gosu postgres repmgr cluster show 
 ID | Name  | Role    | Status        | Upstream | Location | Connection string
----+-------+---------+---------------+----------+----------+-----------------------------------------------------------------------------------------------------------------
 1  | node1 | primary | * running     |          | default  | user=replication_user password=replication_pass host=pgmaster dbname=replication_db port=5432 connect_timeout=2
 2  | node2 | standby | ? unreachable | node1    | default  | user=replication_user password=replication_pass host=pgslave1 dbname=replication_db port=5432 connect_timeout=2
 4  | node4 | standby | ? unreachable | node1    | default  | user=replication_user password=replication_pass host=pgslave3 dbname=replication_db port=5432 connect_timeout=2
 ```
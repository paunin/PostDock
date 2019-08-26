# PostDock - Postgres + Docker

PostgreSQL cluster with **High Availability** and **Self Healing** features for any cloud and docker environment (Amazon, Google Cloud, Kubernetes, Docker Compose, Docker Swarm, Apache Mesos)

![Formula](https://raw.githubusercontent.com/paunin/PostDock/master/artwork/formula2.png)

[![Build Status](https://travis-ci.org/paunin/PostDock.svg?branch=master)](https://travis-ci.org/paunin/PostDock)

- [Info](#info)
  * [Features](#features)
  * [What's in the box](#whats-in-the-box)
  * [Docker images tags convention](#docker-images-tags-convention)
    * [Repositories](#repositories)
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
- [Extended version of postgres](#extended-version-of-postgres)
- [Backups and recovery](#backups-and-recovery)
- [Health-checks](#health-checks)
- [Useful commands](#useful-commands)
- [Publications](#publications)
- [Scenarios](#scenarios)
- [How to contribute](#how-to-contribute)
- [FAQ](#faq)
- [Documentation and manuals](#documentation-and-manuals)

-------

## Info
### Features
* High Availability
* Self Healing and Automated Reconstruction
* [Split Brain](https://en.wikipedia.org/wiki/Split-brain_(computing)) Tolerance
* Eventually/Partially Strict/Strict Consistency modes
* Reads Load Balancing and Connection Pool
* Incremental backup (with optional zero data loss, [RPO=0](https://en.wikipedia.org/wiki/Recovery_point_objective))
* Semi-automated Point In Time Recovery Procedure
* Monitoring exporters for all the components(nodes, balancers, backup)

### What's in the box
[This project](https://github.com/paunin/postgres-docker-cluster) includes:
* Dockerfiles for `postgresql` cluster and backup system
    * [postgresql](./src/Postgres-latest.Dockerfile)
    * [pgpool](./src/Pgpool-latest.Dockerfile)
    * [barman](./src/Barman-latest.Dockerfile)
* Examples of usage(suitable for production environment as architecture has fault protection with auto failover)
    * example of [docker-compose](./docker-compose/latest.yml) file to start this cluster.
    * directory [k8s](./k8s) contains information for building this cluster in Kubernetes

### Docker images tags convention

Taking into account that PostDock project itself has versioning schema, all docker images produced by the repository have schema - `postdock/<component>:<postdock_version>-<component><component_version>-<sub_component><sub_component_version>[...]`, where:

* `<postdock_version>` - semantic version without `bug-fix` component (can be `1.1`, `1.2`, ...)
* `<component>`, `<component_version>` - depends on component:
    * `postgres`,`postgres-extended` - major and minor version without dot in between(can be `95`, `96`, `10`, `11`, ...)
    * `pgpool` - major and minor version of component without dot in between(can be `33`, `36`, `37`, ...)
    * `barman` - major version only (can be `23`, `24`, ...)
* `<sub_component>`, `<sub_component_version>` - depends on component:
    * for `postgres` - `repmgr` can be `32`, `40`, ...
    * for `barman` - `postgres` can be `96`, `10`, `11`, ...
    * for `pgpool` - `postgres` can be `96`, `10`, `11`, ...

Aliases are available **(not recommended to use for production)**:

* `postdock/<component>:latest-<component><component_version>[-<sub_component><sub_component_version>[...]]` - refers to the latest release of the postdock, certain version of the component, certain version of the sub-components(e.g. `postdock/postgres:latest-postgres101-repmgr32`,`postdock/postgres:latest-barman23-postgres101`)
* `postdock/<component>:latest` - refers to the latest release of the postdock and the latest versions of all the components and sub-components (e.g. `postdock/postgres:latest`)
* `postdock/<component>:edge` - refers to build of postdock from master with the latest version the component, and all sub-components (e.g. `postdock/postgres:edge`)

#### Repositories

All available tags (versions and combinations of it) are listed in respective docker-hub repositories:

* [Postgres](https://hub.docker.com/r/postdock/postgres)
* [Pgpool](https://hub.docker.com/r/postdock/pgpool)
* [Barman](https://hub.docker.com/r/postdock/barman)

## Start cluster with docker-compose

To start cluster run it as normal `docker-compose` application `docker-compose -f ./docker-compose/latest.yml up -d pgmaster pgslave1 pgslave2 pgslave3 pgslave4 pgpool backup`

Schema of the example cluster:

```
pgmaster (primary node1)  --|
|- pgslave1 (node2)       --|
|  |- pgslave2 (node3)    --|----pgpool (master_slave_mode stream)
|- pgslave3 (node4)       --|
   |- pgslave4 (node5)    --|
```

Each `postgres` node (`pgmaster`, `pgslaveX`) is managed by `repmgr/repmgrd`. It allows to use automatic `failover` and check cluster status.

Please check comments for each `ENV` variable in [./docker-compose/latest.yml](./docker-compose/latest.yml) file to understand parameter for each cluster node


## Start cluster in Kubernetes

### Using Helm (recomended for production)
You can install PostDock with [Helm](https://helm.sh/) package manager check the [README.md of the package](./k8s/helm/PostDock/README.md) for more information

### Simple (NOT recomended for production)
To make it easier repository contains services' objects under `k8s` dir. Setup `PostgreSQL` cluster following the steps in [the example](./k8s/README.md). It also has information how to check cluster state

## Configuring the cluster

You can configure any node of the cluster(`postgres.conf`) or pgpool(`pgpool.conf`) with ENV variable `CONFIGS` (format: `variable1:value1[,variable2:value2[,...]]`, you can redefine delimiter and assignment symbols by using variables `CONFIGS_DELIMITER_SYMBOL`, `CONFIGS_ASSIGNMENT_SYMBOL`). Also see the Dockerfiles and [docker-compose/latest.yml](./docker-compose/latest.yml) files in the root of the repository to understand all available and used configurations!

### Postgres

For the rest - you better **follow** the advise and look into the [src/Postgres-latest.Dockerfile](./src/Postgres-latest.Dockerfile) file - it full of comments :)

### Pgpool

The most important part to configure in Pgpool (apart of general `CONFIGS`) is backends and users which could access these backends. You can configure backends with ENV variable. You can find good example of setting up pgpool in [docker-compose/latest.yml](./docker-compose/latest.yml) file:

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

The most important part for barman is to setup access variables. Example can be found in [docker-compose/latest.yml](./docker-compose/latest.yml) file:

```
REPLICATION_USER: replication_user # default is replication_user
REPLICATION_PASSWORD: replication_pass # default is replication_pass
REPLICATION_HOST: pgmaster
POSTGRES_PASSWORD: monkey_pass
POSTGRES_USER: monkey_user
POSTGRES_DB: monkey_db
```

### Other configurations

**See the Dockerfiles and [docker-compose/latest.yml](./docker-compose/latest.yml) files in the root of the repository to understand all available and used configurations!**


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

You also will have to set identical ssh keys to all containers. For that you need to mount files with your keys in paths `/tmp/.ssh/keys/id_rsa`, `/tmp/.ssh/keys/id_rsa.pub`.


## Replication slots

If you want to disable the feature of Postgres>=9.4 - [replication slots](https://www.postgresql.org/docs/9.4/static/catalog-pg-replication-slots.html) simply set ENV variable `USE_REPLICATION_SLOTS=0` (enabled by default). So cluster will rely only on Postgres configuration `wal_keep_segments` (`500` by default). You also should remember that default number for configuration `max_replication_slots` is `5`. You can change it (as any other configuration) with ENV variable `CONFIGS`.


## Extended version of postgres

Component `postgres-extended` from the section [Docker images tags convention](#docker-images-tags-convention) should be used if you want to have postgres with extensions and libraries. Each directory [here](./src/pgsql/extensions/bin/extensions) represents extension included in the image.

## Backups and recovery

[Barman](http://docs.pgbarman.org/) is used to provide real-time backups and Point In Time Recovery (PITR)..
This image requires connection information(host, port) and 2 sets of credentials, as you can see from [the Dockerfile](./src/Barman-latest.Dockerfile):

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

*For Disaster Recovery process see [RECOVERY.md](./doc/RECOVERY.md)*

Barman exposes several metrics on `:8080/metrics` for more information see [Barman docs](./barman/README.md)

## Health-checks

To make sure you cluster works as expected without 'split-brain' or other issues, you have to setup health-checks and stop container if any health-check returns non-zero result. That is really useful when you use Kubernetes which has livenessProbe (check how to use it in [the example](./k8s/example2-single-statefulset/nodes/node.yml)) 

* Postgres containers:
    * `/usr/local/bin/cluster/healthcheck/is_major_master.sh` - detect if node acts as a 'false'-master and there is another master - with more standbys
* Pgpool
    * `/usr/local/bin/pgpool/has_enough_backends.sh [REQUIRED_NUM_OF_BACKENDS, default=$REQUIRE_MIN_BACKENDS]` - check if there are enough backend behind `pgpool`
    * `/usr/local/bin/pgpool/has_write_node.sh` - check if one of the backend can be used as a master with write access



## Useful commands

* Get map of current cluster(on any `postgres` node): 
    * `gosu postgres repmgr cluster show` - tries to connect to all nodes on request ignore status of node in `$(get_repmgr_schema).$REPMGR_NODES_TABLE`
    * `gosu postgres psql $REPLICATION_DB -c "SELECT * FROM $(get_repmgr_schema).$REPMGR_NODES_TABLE"` - just select data from tables
* Get `pgpool` status (on any `pgpool` node): `PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h localhost template1 -c "show pool_nodes"`
* In `pgpool` container check if primary node exists: `/usr/local/bin/pgpool/has_write_node.sh` 

Any command might be wrapped with `docker-compose` or `kubectl` - `docker-compose exec {NODE} bash -c '{COMMAND}'` or `kubectl exec {POD_NAME} -- bash -c '{COMMAND}'`


## Scenarios

Check [the document](./doc/FLOWS.md) to understand different cases of failover, split-brain resistance and recovery

## Publications
* [Article on Medium.com](https://medium.com/@dpaunin/postgresql-cluster-into-kubernetes-cluster-f353cde212de)
* [Статья на habr-e](https://habrahabr.ru/post/301370/)

## How to contribute

Check [the doc](./doc/CONTRIBUTE.md) to understand how to contribute

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

#!/usr/bin/env bash
set -e

echo '>>> SETTING UP POLYMORPHIC VARIABLES (repmgr=3+postgres=9 | repmgr=4, postgres=10)... '
source postdock_polymorphic
PG_HOME=$(eval echo ~postgres)
echo '>>> TUNING UP POSTGRES...'
echo "*:$REPLICATION_PRIMARY_PORT:*:$REPLICATION_USER:$REPLICATION_PASSWORD" >> $PG_HOME/.pgpass
chmod 0600 $PG_HOME/.pgpass
chown postgres:postgres $PG_HOME/.pgpass

if ! has_pg_cluster; then
    echo ">>> Cleaning data folder which might have some garbage..."
    rm -rf $PGDATA/*
else
    postgres_configure
fi


export CURRENT_REPLICATION_PRIMARY_HOST=""
CURRENT_MASTER=`cluster_master || echo ''`
echo ">>> Auto-detected master name: '$CURRENT_MASTER'"

if [ -f "$MASTER_ROLE_LOCK_FILE_NAME" ]; then
    echo ">>> The node was acting as a master before restart!"

    if [[ "$CURRENT_MASTER" == "" ]] || [[ "$CURRENT_MASTER" == "$CLUSTER_NODE_NETWORK_NAME" ]]; then
        echo ">>> Can not find new master. Will keep starting postgres normally..."
    else
        echo ">>> Current master is $CURRENT_MASTER. Will clone/rewind it and act as a standby node..."
        rm -f "$MASTER_ROLE_LOCK_FILE_NAME"
        export MASTER_SLAVE_SWITCH="1"
        export CURRENT_REPLICATION_PRIMARY_HOST="$CURRENT_MASTER"
    fi
else
    if [[ "$CURRENT_MASTER" == "" ]]; then
        if [[ "$REPLICATION_PRIMARY_HOST" != "$CLUSTER_NODE_NETWORK_NAME" ]]; then
            export CURRENT_REPLICATION_PRIMARY_HOST="$REPLICATION_PRIMARY_HOST"
        fi
    else
        export CURRENT_REPLICATION_PRIMARY_HOST="$CURRENT_MASTER"
    fi
fi

chown -R postgres $PGDATA && chmod -R 0700 $PGDATA

source /usr/local/bin/cluster/repmgr/configure.sh

echo ">>> Sending in background postgres start..."
if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" == "" ]]; then
    cp -f /usr/local/bin/cluster/postgres/primary/entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh postgres &
else
    /usr/local/bin/cluster/postgres/standby/entrypoint.sh
fi

/usr/local/bin/cluster/repmgr/start.sh
#!/usr/bin/env bash
set -e

CURRENT_MASTER=`cluster_master || echo ''`
echo ">>> Auto-detected master name: '$CURRENT_MASTER'"

if [ -f "$MASTER_ROLE_LOCK_FILE_NAME" ]; then
    echo ">>> The node was acting as a master before restart!"

    if [[ "$CURRENT_MASTER" == "" ]]; then
        echo ">>> Can not find new master. Will keep starting postgres normally..."
        export CURRENT_REPLICATION_PRIMARY_HOST=""
    else
        echo ">>> Current master is $CURRENT_MASTER. Will clone it and act as a standby node..."
        rm -f "$MASTER_ROLE_LOCK_FILE_NAME"
        export FORCE_CLEAN=1
        export CURRENT_REPLICATION_PRIMARY_HOST="$CURRENT_MASTER"
    fi
else
    if [[ "$CURRENT_MASTER" == "" ]]; then
        export CURRENT_REPLICATION_PRIMARY_HOST="$REPLICATION_PRIMARY_HOST"
    else
        export CURRENT_REPLICATION_PRIMARY_HOST="$CURRENT_MASTER"
    fi
fi


if [ `ls $PGDATA/ | wc -l` != "0" ]; then
    echo ">>> Data folder is not empty $PGDATA:"
    ls -al $PGDATA
    if [[ "$FORCE_CLEAN" == "1" ]] || ! has_pg_cluster; then
        echo ">>> Cleaning data folder..."
        rm -rf $PGDATA/*
    fi
fi
chown -R postgres $PGDATA && chmod -R 0700 $PGDATA

/usr/local/bin/cluster/repmgr/configure.sh

echo ">>> Sending in background postgres start..."
if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" == "" ]]; then
    cp -f /usr/local/bin/cluster/postgres/primary/entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh postgres &
else
    /usr/local/bin/cluster/postgres/standby/entrypoint.sh &
fi

/usr/local/bin/cluster/repmgr/start.sh
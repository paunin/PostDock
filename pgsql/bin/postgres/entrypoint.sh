#!/usr/bin/env bash
set -e

export CURRENT_NODE_TYPE="$INITIAL_NODE_TYPE"
export CURRENT_REPLICATION_PRIMARY_HOST="$REPLICATION_PRIMARY_HOST"
export CURRENT_REPLICATION_UPSTREAM_NODE_ID="$REPLICATION_UPSTREAM_NODE_ID"

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
if [[ "$CURRENT_NODE_TYPE" == "master" ]]; then
    cp -f /usr/local/bin/cluster/postgres/primary/entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh postgres &
else
    /usr/local/bin/cluster/postgres/standby/entrypoint.sh &
fi

/usr/local/bin/cluster/repmgr/start.sh
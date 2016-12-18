#!/usr/bin/env bash
set -e

if [ `ls $PGDATA/ | wc -l` != "0" ]; then
    echo ">>> Data folder is not empty $PGDATA:"
    ls -al $PGDATA

    if [[ "$FORCE_CLEAN" == "1" ]]; then
        echo ">>> Cleaning data folder..."
        rm -rf $PGDATA/*
    fi
fi

chown -R postgres $PGDATA && chmod -R 0700 $PGDATA

echo ">>> Setting up repmgr..."
/usr/local/bin/cluster/repmgr_configure.sh

echo ">>> Sending in background postgres start..."
if [[ "$INITIAL_NODE_TYPE" == "master" ]]; then
    #default for postgres image entrypoint with custom script
    cp -f /usr/local/bin/cluster/primary.entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh "$@" &
else
    #redifined entrypoint for standby mode
    /usr/local/bin/cluster/standby.entrypoint.sh "$@" &
fi

echo ">>> Waiting postgres on this node to start repmgr..."
wait_db $CLUSTER_NODE_NETWORK_NAME $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB

echo ">>> Registering node with initial role $INITIAL_NODE_TYPE"
gosu postgres repmgr $INITIAL_NODE_TYPE register --force

echo ">>> Starting repmgr daemon..."
rm -rf /tmp/repmgrd.pid
gosu postgres repmgrd -vvv --pid-file=/tmp/repmgrd.pid
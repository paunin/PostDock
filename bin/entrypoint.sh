#!/bin/bash
if [[ "$FORCE_CLEAN" == "1" ]]; then
    rm -rf $PGDATA/*
fi
DAEMON_STARTUP_DELAY=`expr $REPLICATION_STANDBY_START_DELAY + $CLUSTER_NODE_REGISTER_DELAY + $REPLICATION_DAEMON_START_DELAY`;

/usr/local/bin/cluster/repmgr_configure.sh

if [[ "$INITIAL_NODE_TYPE" == "master" ]]; then
    cp -f /usr/local/bin/cluster/primary.entrypoint.sh /docker-entrypoint-initdb.d/
    /docker-entrypoint.sh "$@" &
else
    /usr/local/bin/cluster/standby.entrypoint.sh "$@" &
fi

echo ">>> Waiting $DAEMON_STARTUP_DELAY seconds to start repmgr daemon"
sleep $DAEMON_STARTUP_DELAY

echo ">>> Starting repmgr daemon..."
rm -rf /tmp/repmgrd.pid
gosu postgres repmgrd -vvv --pid-file=/tmp/repmgrd.pid
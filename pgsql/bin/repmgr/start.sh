#!/usr/bin/env bash
set -e

echo ">>> Waiting $REPMGR_WAIT_POSTGRES_START_TIMEOUT seconds for postgres on this node to start repmgr..."
wait_db $CLUSTER_NODE_NETWORK_NAME $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB $REPMGR_WAIT_POSTGRES_START_TIMEOUT
sleep "$WAIT_SYSTEM_IS_STARTING"


if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" == "" ]]; then
    NODE_TYPE='master'
else
    NODE_TYPE='standby'
fi

echo ">>> Registering node with role $NODE_TYPE"
gosu postgres repmgr "$NODE_TYPE" register --force || echo ">>>>>> Can't re-register node. Means it has been already done before!"

if [[ "$NODE_TYPE" == 'standby' ]]; then
    gosu postgres /usr/local/bin/cluster/repmgr/events/execs/includes/lock_standby.sh
fi

echo ">>> Starting repmgr daemon..."
rm -rf /tmp/repmgrd.pid
gosu postgres repmgrd -vvv --pid-file=/tmp/repmgrd.pid
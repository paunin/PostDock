#!/usr/bin/env bash
set -e

if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" == "" ]]; then
    NODE_TYPE='master'
else
    NODE_TYPE='standby'
    wait_replication 1
fi
wait_local_postgres

echo ">>> Registering node with role $NODE_TYPE"
gosu postgres repmgr "$NODE_TYPE" register --force || echo ">>>>>> Can't re-register node. Means it has been already done before!"

if [[ "$NODE_TYPE" == 'standby' ]]; then
    gosu postgres /usr/local/bin/cluster/repmgr/events/execs/includes/lock_standby.sh
fi

echo ">>> Starting repmgr daemon..."
rm -rf "$REPMGR_PID_FILE"
gosu postgres repmgrd -vvv --pid-file="$REPMGR_PID_FILE"

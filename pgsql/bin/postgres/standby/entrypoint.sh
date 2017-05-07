#!/usr/bin/env bash
set -e

echo ">>> Waiting for primary node..."
dockerize -wait tcp://$CURRENT_REPLICATION_PRIMARY_HOST:$REPLICATION_PRIMARY_PORT -timeout 300s
sleep "$WAIT_SYSTEM_IS_STARTING" && sleep 5

echo ">>> Starting standby node..."
if ! has_pg_cluster; then
    echo ">>>>>> Instance hasn't been set up yet. Clonning primary node..."
    PGPASSWORD=$REPLICATION_PASSWORD gosu postgres repmgr -h $CURRENT_REPLICATION_PRIMARY_HOST -U $REPLICATION_USER -d $REPLICATION_DB -D $PGDATA standby clone --fast-checkpoint --force

fi

rm -f $MASTER_ROLE_LOCK_FILE_NAME # that file should not be here
echo ">>> Starting postgres..."
exec gosu postgres postgres
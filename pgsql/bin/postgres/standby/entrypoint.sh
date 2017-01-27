#!/usr/bin/env bash
set -e

echo ">>> Waiting for primary node..."
wait_db $CURRENT_REPLICATION_PRIMARY_HOST $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB

echo ">>> Starting standby node..."
if ! has_pg_cluster; then
    echo ">>>>>> Instance hasn't been set up yet. Clonning primary node..." && sleep 10
    PGPASSWORD=$REPLICATION_PASSWORD gosu postgres repmgr -h $CURRENT_REPLICATION_PRIMARY_HOST -U $REPLICATION_USER -d $REPLICATION_DB -D $PGDATA standby clone --fast-checkpoint --force
fi

echo ">>> Starting postgres..."
exec gosu postgres postgres
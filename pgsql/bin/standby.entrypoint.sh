#!/usr/bin/env bash
set -e

echo ">>> Waiting for primary node..."
wait_db $REPLICATION_PRIMARY_HOST $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB

echo ">>> Starting standby node..."
if [ `ls $PGDATA/ | wc -l` = "0" ]; then
    echo ">>>>>> Instance hasn't been set up yet, setting up..."
    chmod g+s /run/postgresql
    chown -R postgres /run/postgresql
    
    echo ">>>>>> Clonning primary node..." && sleep 5
    PGPASSWORD=$REPLICATION_PASSWORD gosu postgres repmgr -h $REPLICATION_PRIMARY_HOST -U $REPLICATION_USER -d $REPLICATION_DB -D $PGDATA standby clone
fi

echo ">>> Starting postgres..."
if [ "${1:0:1}" = '-' ]; then
    set -- postgres "$@"
fi

if [ "$1" = 'postgres' ]; then
    exec gosu postgres "$@"
fi

exec "$@"
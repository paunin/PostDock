#!/bin/bash
set -e

wait_db $REPLICATION_PRIMARY_HOST $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB

echo ">>> Starting standby node..."

if [ ! -d "/var/cluster_archive" ]; then
    mkdir -m 0700 /var/cluster_archive
fi
chown -R postgres /var/cluster_archive
chmod -R 0700 /var/cluster_archive

chown -R postgres $PGDATA
chmod -R 0700 $PGDATA

# Instance has been already set up
if [ `ls $PGDATA/ | wc -l` = "0" ]; then
    chmod g+s /run/postgresql
    chown -R postgres /run/postgresql

    PGPASSWORD=$REPLICATION_PASSWORD gosu postgres repmgr -h $REPLICATION_PRIMARY_HOST -U $REPLICATION_USER -d $REPLICATION_DB -D $PGDATA standby clone
fi


if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi

if [ "$1" = 'postgres' ]; then
	exec gosu postgres "$@"
fi

exec "$@"
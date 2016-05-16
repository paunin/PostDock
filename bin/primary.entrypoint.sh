#!/bin/bash

cp -f /var/cluster_configs/postgresql.conf $PGDATA/postgresql.conf

if [ ! -d "/var/cluster_archive" ]; then
    mkdir -m 0700 /var/cluster_archive
fi
chown -R postgres /var/cluster_archive
chmod -R 0700 /var/cluster_archive

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE ROLE $REPLICATION_USER WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' SUPERUSER CREATEDB  CREATEROLE INHERIT LOGIN;"
gosu postgres createdb $REPLICATION_DB -O $REPLICATION_USER


echo "host replication $REPLICATION_USER 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf

/usr/local/bin/cluster/repmgr_register.sh
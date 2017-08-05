#!/usr/bin/env bash
set -e

wait_upstream_postgres 5

echo ">>> Starting standby node..."
if ! has_pg_cluster; then
    echo ">>> Instance hasn't been set up yet."
    do_replication
else
    echo ">>> Instance has been set up already."
    do_rewind
fi

rm -f $MASTER_ROLE_LOCK_FILE_NAME # that file should not be here
echo ">>> Starting postgres..."
exec gosu postgres postgres

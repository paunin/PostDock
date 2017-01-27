#!/usr/bin/env bash
set -e

echo ">>> Setting up repmgr..."
REPMGR_CONFIG_FILE=/etc/repmgr.conf
cp -f /var/cluster_configs/repmgr.conf $REPMGR_CONFIG_FILE

if [ -z "$CLUSTER_NODE_NETWORK_NAME" ]; then
    CLUSTER_NODE_NETWORK_NAME="`hostname`"
fi

# Need this loopback to speedup connections, also k8s doesn't have DNS loopback by service name on the same pod
echo ">>> Adding loopback '127.0.0.1 $CLUSTER_NODE_NETWORK_NAME'"
echo "127.0.0.1 $CLUSTER_NODE_NETWORK_NAME" >> /etc/hosts


echo ">>> Setting up repmgr config file '$REPMGR_CONFIG_FILE'..."
echo "

pg_bindir=/usr/lib/postgresql/$PG_MAJOR/bin
cluster=$CLUSTER_NAME
node=$NODE_ID
node_name=$NODE_NAME
conninfo='user=$REPLICATION_USER password=$REPLICATION_PASSWORD host=$CLUSTER_NODE_NETWORK_NAME dbname=$REPLICATION_DB port=$REPLICATION_PRIMARY_PORT connect_timeout=$CONNECT_TIMEOUT'
failover=automatic
promote_command='PGPASSWORD=$REPLICATION_PASSWORD repmgr standby promote --log-level DEBUG --verbose'
follow_command='PGPASSWORD=$REPLICATION_PASSWORD repmgr standby follow -W --log-level DEBUG --verbose'
reconnect_attempts=$RECONNECT_ATTEMPTS
reconnect_interval=$RECONNECT_INTERVAL
master_response_timeout=$MASTER_RESPONSE_TIMEOUT
loglevel=$LOG_LEVEL
" >> $REPMGR_CONFIG_FILE

echo ">>> Setting up upstream node..."
if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" != "" ]]; then

    wait_db $CURRENT_REPLICATION_PRIMARY_HOST $REPLICATION_PRIMARY_PORT $REPLICATION_USER $REPLICATION_PASSWORD $REPLICATION_DB
    sleep 10
    # Getting upstream node ID by name CURRENT_REPLICATION_PRIMARY_HOST
    REPLICATION_UPSTREAM_NODE_ID=`PGPASSWORD=$REPLICATION_PASSWORD psql --username "$REPLICATION_USER" -h $CURRENT_REPLICATION_PRIMARY_HOST -p $REPLICATION_PRIMARY_PORT -d $REPLICATION_DB -tAc "SELECT id FROM repmgr_$CLUSTER_NAME.repl_nodes WHERE conninfo LIKE '% host=$REPLICATION_PRIMARY_HOST%'  ORDER BY id"`
    if [[ "$REPLICATION_UPSTREAM_NODE_ID" == "" ]]; then
        echo ">>> Can not get REPLICATION_UPSTREAM_NODE_ID by CURRENT_REPLICATION_PRIMARY_HOST=$CURRENT_REPLICATION_PRIMARY_HOST"
        exit 1
    fi

    echo "upstream_node=$REPLICATION_UPSTREAM_NODE_ID" >> $REPMGR_CONFIG_FILE
fi
chown postgres $REPMGR_CONFIG_FILE
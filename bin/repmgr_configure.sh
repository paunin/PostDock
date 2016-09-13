#!/bin/bash

if [ -z "$CLUSTER_NODE_NETWORK_NAME" ]; then
    CLUSTER_NODE_NETWORK_NAME="`hostname`"
fi

echo "127.0.0.1 $CLUSTER_NODE_NETWORK_NAME" >> /etc/hosts
# Need this loopback to speedup connections and also k8s doesn't have DNS loopback by service name on the same pod

echo "cluster=$CLUSTER_NAME
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
" >> /etc/repmgr.conf

chown postgres /etc/repmgr.conf

if [[ "$INITIAL_NODE_TYPE" != "master" ]]; then
    if [ -n "$REPLICATION_UPSTREAM_NODE_ID" ]; then

        if [[ "$NODE_ID" != "$REPLICATION_UPSTREAM_NODE_ID" ]]; then
            echo "upstream_node=$REPLICATION_UPSTREAM_NODE_ID" >> /etc/repmgr.conf
        else
            echo "Misconfiguration of upstream node, NODE_ID=$NODE_ID AND REPLICATION_UPSTREAM_NODE_ID=$REPLICATION_UPSTREAM_NODE_ID"
            exit 1
        fi
    else
        echo "For node with initial type $INITIAL_NODE_TYPE you have to setup REPLICATION_UPSTREAM_NODE_ID"
        exit 1
    fi
fi
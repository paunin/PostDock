#!/usr/bin/env bash
set -e

echo ">>> Setting up repmgr..."

if [ -z "$CLUSTER_NODE_NETWORK_NAME" ]; then
    export CLUSTER_NODE_NETWORK_NAME="`hostname`"
fi


echo ">>> Setting up repmgr config file '$REPMGR_CONFIG_FILE'..."
echo "
event_notification_command='/usr/local/bin/cluster/repmgr/events/router.sh %n %e %s \"%t\" \"%d\"'
ssh_options='-o \"StrictHostKeyChecking no\" -v'
use_replication_slots=$USE_REPLICATION_SLOTS
pg_bindir='/usr/lib/postgresql/$PG_MAJOR/bin'

$REPMGR_NODE_ID_PARAM_NAME=$(get_node_id)
node_name=$NODE_NAME
conninfo='user=$REPLICATION_USER password=$REPLICATION_PASSWORD host=$CLUSTER_NODE_NETWORK_NAME dbname=$REPLICATION_DB port=$REPLICATION_PRIMARY_PORT connect_timeout=$CONNECT_TIMEOUT'
failover=automatic
promote_command='PGPASSWORD=\'$REPLICATION_PASSWORD\' repmgr standby promote --log-level DEBUG --verbose'
follow_command='PGPASSWORD=\'$REPLICATION_PASSWORD\' repmgr standby follow -W --log-level DEBUG --verbose'
reconnect_attempts=$RECONNECT_ATTEMPTS
reconnect_interval=$RECONNECT_INTERVAL
$REPMGR_LOG_LEVEL_PARAM_NAME=$LOG_LEVEL
priority=$NODE_PRIORITY
" >> $REPMGR_CONFIG_FILE

echo ">>> Setting up upstream node..."
if [[ "$CURRENT_REPLICATION_PRIMARY_HOST" != "" ]]; then

    LOCKED_STANDBY=`cat $STANDBY_ROLE_LOCK_FILE_NAME || echo ''`
    echo ">>> Previously Locked standby upstream node LOCKED_STANDBY='$LOCKED_STANDBY'"
    if [[ "$LOCKED_STANDBY" != '' ]]; then
        REPLICATION_UPSTREAM_NODE_ID="$LOCKED_STANDBY"
    else
        wait_upstream_postgres
        wait_upstream_node_id
        REPLICATION_UPSTREAM_NODE_ID=`get_upstream_node_id`
    fi

    if [[ "$REPLICATION_UPSTREAM_NODE_ID" == "" ]]; then
        echo ">>> Can not get REPLICATION_UPSTREAM_NODE_ID from LOCK file or by CURRENT_REPLICATION_PRIMARY_HOST=$CURRENT_REPLICATION_PRIMARY_HOST"
        exit 1
    else 
        echo ">>> REPLICATION_UPSTREAM_NODE_ID=$REPLICATION_UPSTREAM_NODE_ID"
    fi
    set_repmgr_upstream_node
fi
chown postgres $REPMGR_CONFIG_FILE

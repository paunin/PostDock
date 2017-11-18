#!/usr/bin/env bash
NEW_UPSTREAM_NODE_ID=`psql $REPLICATION_DB -tAc "SELECT upstream_node_id FROM repmgr_$CLUSTER_NAME.repl_nodes WHERE id=$NODE_ID"`
if [[ "$NEW_UPSTREAM_NODE_ID" != "" ]]; then
    echo "$BAR Locking standby (NEW_UPSTREAM_NODE_ID=$NEW_UPSTREAM_NODE_ID)..."
    echo "$NEW_UPSTREAM_NODE_ID" > $STANDBY_ROLE_LOCK_FILE_NAME
fi
#!/usr/bin/env bash
set -u
set -e

# get master id
REPMGR_SCHEMA="repmgr_$CLUSTER_NAME"
MASTER_ID=`PGPASSWORD=$REPLICATION_PASSWORD psql -d $REPLICATION_DB -U $REPLICATION_USER -p $REPLICATION_PRIMARY_PORT -t -A \
  -c "SELECT id FROM ${REPMGR_SCHEMA}.repl_nodes WHERE active = TRUE AND type='master'"`

# remove from pool
pcp_detach_node $PCP_HOST $PCP_PORT $PCP_USER $PCP_PASSWORD $MASTER_ID

# Promote this node from standby to master
repmgr standby promote -f $REPMGR_CONFIG_FILE --log-level DEBUG --verbose

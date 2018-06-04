#!/usr/bin/env bash

# ====================================== What is my name?
MY_NAME=$NODE_NAME
echo ">>> My name is $MY_NAME"

# ====================================== Do I feel like master
AM_I_MASTER=`PGPASSWORD=$REPLICATION_PASSWORD psql -h $CLUSTER_NODE_NETWORK_NAME -U $REPLICATION_USER -p $REPLICATION_PRIMARY_PORT $REPLICATION_DB  -tAc "SELECT * FROM $(get_repmgr_schema).$REPMGR_NODES_TABLE WHERE $REPMGR_NODE_NAME_COLUMN='$MY_NAME' AND (type='primary' OR type='master')" | wc -l`
if [[ "$AM_I_MASTER" -eq "0" ]]; then
    echo ">>> I'm not master at all! No worries!"
    exit 0
else
    echo ">>> I think I'm master. Will ask my neighbors if they agree."
fi

# ====================================== Build master map
FAILED_NODES=0


# ====================================== Cascade replication? Adaptive mode?
unset NODES

if [ "$PARTNER_NODES" != "" ]; then
    echo ">>> Will ask nodes from PARTNER_NODES list"
    IFS=',' read -ra NODES <<< "$PARTNER_NODES"
else
    DIFFERENT_UPSTREAMS=`PGPASSWORD=$REPLICATION_PASSWORD psql -h $CLUSTER_NODE_NETWORK_NAME -U $REPLICATION_USER -p $REPLICATION_PRIMARY_PORT $REPLICATION_DB  -tAc "SELECT upstream_node_id FROM $(get_repmgr_schema).$REPMGR_NODES_TABLE" | uniq | awk '{$1=$1};1' | grep -v -e '^[[:space:]]*$' | wc -l`
    if [[ "$DIFFERENT_UPSTREAMS" -gt "1" ]]; then
        echo ">>> I can't work with cascade replication without PARTNER_NODES list! Will not run check!"
        exit 0
    fi
    echo ">>> Will ask all nodes in the cluster"
    # TODO: Does not make array here
    read -d '' -ra NODES <<<`PGPASSWORD=$REPLICATION_PASSWORD psql -h $CLUSTER_NODE_NETWORK_NAME -U $REPLICATION_USER -p $REPLICATION_PRIMARY_PORT $REPLICATION_DB  -tAc "SELECT conninfo FROM $(get_repmgr_schema).$REPMGR_NODES_TABLE" | grep host | awk '{print $3}' | cut -d "=" -f2`
fi

NODES_COUNT="${#NODES[@]}"

unset MASTERS_MAP
declare -A MASTERS_MAP

for NODE in "${NODES[@]}"; do
    NO_ROUTE=false
    echo ">>> Checking node $NODE"

    MASTER=`PGCONNECT_TIMEOUT=$CHECK_PGCONNECT_TIMEOUT PGPASSWORD=$REPLICATION_PASSWORD psql -h $NODE -U $REPLICATION_USER -p $REPLICATION_PRIMARY_PORT $REPLICATION_DB  -tAc "SELECT upstream_node_name FROM $(get_repmgr_schema).$REPMGR_SHOW_NODES_TABLE WHERE conninfo LIKE '%host=$NODE%' AND (upstream_node_name IS NOT NULL AND upstream_node_name <>'') AND active=true"`
    if [[ "$?" -ne "0" ]]; then
        FAILED_NODES=$((FAILED_NODES + 1))
        echo ">>>>>> Failed nodes - $FAILED_NODES"
        continue
    fi

    if [[ "$MASTER" != "" ]]; then
        MASTER_COUNT="${MASTERS_MAP[$MASTER]}"
        MASTER_COUNT=$(( MASTER_COUNT + 1 ))
        echo ">>>>>>>>> Count of references to potential master $MASTER is $MASTER_COUNT now"
        MASTERS_MAP[$MASTER]="$MASTER_COUNT"
    fi

done

# ====================================== Display masters map
echo ">>> Potential masters got references:"
for NODE in "${!MASTERS_MAP[@]}"
do
  echo ">>>>>> Node: $NODE, references: ${MASTERS_MAP[$NODE]}"
done


# ====================================== Could I reach majority of nodes?
ANTI_QUORUM=$((NODES_COUNT - NODES_COUNT / 2))
if [[ "$FAILED_NODES" -ge "$ANTI_QUORUM" ]]; then
    echo ">>> Could not reach enough nodes! I'm false-master! (FAILED_NODES = $FAILED_NODES , ANTI_QUORUM = $ANTI_QUORUM)"
    exit 1
fi

# ====================================== Do I have more standbys then anyone else?
REFERENCES_TO_ME="${MASTERS_MAP[$MY_NAME]}"

if [[ "$REFERENCES_TO_ME" == "" ]]; then
    REFERENCES_TO_ME="0"
else
    unset "MASTERS_MAP[$MY_NAME]"
fi


echo ">>> I have $REFERENCES_TO_ME incoming reference[s]! Does anyone have more?"
for NODE in "${!MASTERS_MAP[@]}"
do
    if [[ "${MASTERS_MAP[$NODE]}" -ge "$REFERENCES_TO_ME" ]]; then
        echo ">>>>>> Node $NODE has ${MASTERS_MAP[$NODE]} reference[s], which is equal or more then I do! Looks like I'm false master!";
        exit 1
    fi
done

echo ">>> Yahoo! I'm real master...so I think!"
exit 0
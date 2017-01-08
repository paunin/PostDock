#!/usr/bin/env bash

# ====================================== Cascade replication?
DIFFERENT_UPSTREAMS=`gosu postgres repmgr cluster show | tail -n +3 | grep -v '* master' | awk -F"|" '{print $3}' | uniq | awk '{$1=$1};1' | wc -l`
if [[ "$DIFFERENT_UPSTREAMS" -gt "1" ]]; then
    echo ">>> I can't work with cascade replication! Will not run check! "
    exit 0
fi

# ====================================== What is my name?
MY_NAME=$NODE_NAME
echo ">>> My name is $MY_NAME"

# ====================================== Do I feel like master
AM_I_MASTER=`gosu postgres repmgr cluster show | grep '* master' | awk -F"|" '{print $2}' | grep "$MY_NAME" | wc -l`
if [[ "$AM_I_MASTER" -eq "0" ]]; then
    echo ">>> I'm not master at all! No worries!"
    exit 0
else
    echo ">>> I think I'm master. Will ask my neighbors if they agree."
fi

# ====================================== Build master map
FAILED_NODES=0
NODES=`gosu postgres psql $REPLICATION_DB -c "SELECT conninfo FROM repmgr_$CLUSTER_NAME.repl_show_nodes WHERE cluster='$CLUSTER_NAME'" | grep host | awk '{print $3}' | cut -d "=" -f2`
NODES_COUNT=`echo "$NODES" | wc -l`

unset MASTERS_MAP
declare -A MASTERS_MAP

for NODE in $NODES; do
    NO_ROUTE=false
    echo ">>> Checking node $NODE"
    CLUSTER_STATUS=`gosu postgres ssh -n "$NODE" repmgr cluster show`
    if [[ "$?" -ne "0" ]]; then
        FAILED_NODES=$((FAILED_NODES + 1))
        echo ">>>>>> Failed nodes - $FAILED_NODES"
        continue
    fi

    MASTERS=`echo "$CLUSTER_STATUS" | tail -n +3 | grep -v FAILED | grep -v '* master' | awk -F"|" '{print $3}' | awk '{$1=$1};1'`

    for MASTER in $MASTERS; do
        MASTER_COUNT="${MASTERS_MAP[$MASTER]}"
        MASTER_COUNT=$(( MASTER_COUNT + 1 ))
        echo ">>>>>>>>> Count of references to potential master $MASTER is $MASTER_COUNT now"
        MASTERS_MAP[$MASTER]="$MASTER_COUNT"
    done
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
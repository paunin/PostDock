#!/usr/bin/env bash
set -e

SLOTS_COUNT=`barman show-server $UPSTREAM_NAME | grep "replication_slot: Record(slot_name='$REPLICATION_SLOT_NAME'" | wc -l`
if [ "$SLOTS_COUNT" -gt "0" ]; then 
	echo "Looks like replication slot already exists"
else 
	echo "Creating replication slot: $REPLICATION_SLOT_NAM"
	barman receive-wal --create-slot $UPSTREAM_NAME
fi

barman cron

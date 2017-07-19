#!/usr/bin/env bash

if [[ "$1" != "" ]]; then
    ENOUGH_BACKENDS=$1
else
    ENOUGH_BACKENDS="$REQUIRE_MIN_BACKENDS"
fi

if [[ "$ENOUGH_BACKENDS" == "0" ]]; then
    echo ">>> I don't need any backends to be healthy!"
    exit 0
fi

POOL=`PGCONNECT_TIMEOUT=$CHECK_PGCONNECT_TIMEOUT PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h 127.0.0.1 template1 -c 'show pool_nodes'`

if [[ "$?" -ne "0" ]]; then
    echo ">>> Could not get nodes in my pool!"
    exit 1
fi
HEALTHY_BACKENDS=`echo "$POOL" | tail -n +3 | awk -F"|"  '{print $4}' | grep 'up\|2' | wc -l`

echo ">>> I need at least $ENOUGH_BACKENDS backends, have $HEALTHY_BACKENDS."

if [ "$HEALTHY_BACKENDS" -lt "$ENOUGH_BACKENDS" ]; then
    echo ">>> Don't have enough backends!"
    exit 1
else
    echo ">>> Have enough backends!"
    exit 0
fi
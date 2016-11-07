#!/usr/bin/env bash

DB_EXISTS=''
MAX_TRIES=50
SLEEP_TIME=5


HOST=$1
PORT=$2
USER=$3
PASSWORD=$4
DB=$5
echo ">>> Will wait db $DB on $HOST:$PORT, will try $MAX_TRIES times with delay $SLEEP_TIME seconds"
while [[ "$MAX_TRIES" != "0" ]]
do

    DB_EXISTS=`PGPASSWORD=$PASSWORD psql --username "$USER" -h $HOST -p $PORT -tAc "SELECT 1 FROM pg_database WHERE datname='$DB'" template1`
    if [[ "$DB_EXISTS" != "1" ]]; then
        echo ">>> Db $DB still does not exist on $HOST:$PORT (will try $MAX_TRIES times)"
        sleep "$SLEEP_TIME"
    else
        echo ">>> Db $DB exists on $HOST:$PORT!"
        break
    fi
    MAX_TRIES=`expr "$MAX_TRIES" - 1`
done

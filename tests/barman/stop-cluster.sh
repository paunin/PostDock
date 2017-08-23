#!/bin/bash
set -e

STOP_COMMAND="touch /var/run/recovery.lock && killall repmgrd && gosu postgres pg_ctl stop";
docker-compose exec pgslave1 sh -c "$STOP_COMMAND"
docker-compose exec pgslave2 sh -c "$STOP_COMMAND"
docker-compose exec pgslave3 sh -c "$STOP_COMMAND"
docker-compose exec pgslave4 sh -c "$STOP_COMMAND"
docker-compose exec pgmaster sh -c "$STOP_COMMAND"

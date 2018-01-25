#!/usr/bin/env bash
OLD_COMPOSE_FILE=$COMPOSE_FILE
export COMPOSE_FILE=./tests/pgsql-configs/docker-compose.yml

docker-compose down
docker-compose build
docker-compose up -d postgres
set -e

sleep 10

if [ "2" != `docker-compose exec postgres gosu postgres bash -c 'cat $PGDATA/postgresql.conf' | grep "listen_addresses = 'some_host'\|max_replication_slots = 55" | wc -l | tr -d ' '` ]; then
    exit 1
fi

docker-compose down
export COMPOSE_FILE=$OLD_COMPOSE_FILE
#!/usr/bin/env bash
OLD_COMPOSE_FILE=$COMPOSE_FILE
export COMPOSE_FILE=./tests/extensions-are-available/docker-compose.yml

docker-compose down
docker-compose build
docker-compose up -d postgres
sleep 30
set -e

for EXTENSION in postgis;
do
    echo ">>> Checking now: $EXTENSION"
    docker-compose exec -T postgres bash -c "gosu postgres psql -c 'CREATE EXTENSION $EXTENSION'"
done

for LIB in libpgosm.so;
do
    echo ">>> Checking now: $LIB"
    docker-compose exec -T postgres gosu postgres psql -c "load '$LIB'"
done

#I can create extension in the running container
docker-compose down
export COMPOSE_FILE=$OLD_COMPOSE_FILE
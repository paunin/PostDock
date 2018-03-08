#!/usr/bin/env bash

docker-compose up -d postgres_ext
sleep 30
set -e

for EXTENSION in postgis pglogical pgl_ddl_deploy;
do
    echo ">>> Checking now: $EXTENSION"
    docker-compose exec -T postgres_ext bash -c "gosu postgres psql -c 'CREATE EXTENSION $EXTENSION'"
done

for LIB in libpgosm.so;
do
    echo ">>> Checking now: $LIB"
    docker-compose exec -T postgres_ext gosu postgres psql -c "load '$LIB'"
done


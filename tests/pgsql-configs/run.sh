#!/usr/bin/env bash

docker-compose up -d postgres_conf
set -e

sleep 10

if [ "2" != `docker-compose exec postgres_conf gosu postgres bash -c 'cat $PGDATA/postgresql.conf' | grep "listen_addresses = 'some_host'\|max_replication_slots = 55" | wc -l | tr -d ' '` ]; then
    exit 1
fi
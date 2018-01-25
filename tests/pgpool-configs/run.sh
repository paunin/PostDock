#!/usr/bin/env bash
OLD_COMPOSE_FILE=$COMPOSE_FILE
export COMPOSE_FILE=./tests/pgpool-configs/docker-compose.yml

docker-compose down
docker-compose build
docker-compose up -d pgpool
set -e

sleep 10

if [ "2" != `docker-compose exec pgpool gosu postgres bash -c 'cat /usr/local/etc/pgpool.conf' | grep "num_init_children = 12\|max_pool = '13'" | wc -l | tr -d ' '` ]; then
    exit 1
fi

docker-compose down
export COMPOSE_FILE=$OLD_COMPOSE_FILE
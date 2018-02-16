#!/usr/bin/env bash

docker-compose up -d pgpool_conf
set -e

if [ "2" != `docker-compose exec pgpool_conf gosu postgres bash -c 'cat /usr/local/etc/pgpool.conf' | grep "num_init_children = 12\|max_pool = 13" | wc -l | tr -d ' '` ]; then
    exit 1
fi
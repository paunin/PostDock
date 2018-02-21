#!/usr/bin/env bash

docker-compose up -d postgres_conf
set -e

sleep 10
NODE_ID=`docker-compose exec -T postgres_conf get_node_id`
if [ "1102" != "$NODE_ID" ]; then
    echo "Node id should be 1102, currently '$NODE_ID'"
    exit 1
fi

#!/usr/bin/env bash

docker-compose up -d pgmaster pgslave1
set -e

sleep 3

docker-compose exec pgslave1 bash -c 'gosu postgres echo "SSH_CHECK" > /tmp/ssh_check'
CHECKED_TEXT=

if [[ "1" != `docker-compose exec pgmaster bash -c 'gosu postgres ssh -o LogLevel=QUIET -t pgslave1 "cat /tmp/ssh_check"' | grep SSH_CHECK | wc -l | tr -d ' '` ]]; then
    exit 1
fi
#!/usr/bin/env bash

docker-compose down -v && docker-compose build && docker-compose up -d pgmaster pgslave1 pgslave3

docker-compose exec -T pgmaster wait_local_postgres
docker-compose exec -T pgslave1 wait_local_postgres
docker-compose exec -T pgslave3 wait_local_postgres
sleep 10
docker-compose exec pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts && echo 1.1.1.1 pgslave1 >> /etc/hosts"
sleep 40

SLAVE_EXIT=`docker-compose ps | grep pgslave3 | grep Exit | wc -l | tr -d ' '`
if [[ "$SLAVE_EXIT" != "1" ]]; then
    echo '>>> Isolated slave should die!';
    exit 1
fi


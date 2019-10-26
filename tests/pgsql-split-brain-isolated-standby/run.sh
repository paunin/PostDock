#!/usr/bin/env bash

docker-compose up -d pgmaster pgslave1 pgslave3

docker-compose exec -T pgmaster wait_local_postgres
docker-compose exec -T pgslave1 wait_local_postgres
docker-compose exec -T pgslave3 wait_local_postgres
sleep 10
echo ">>> Isolating pgslave3..."
docker-compose exec pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts && echo 1.1.1.2 pgslave1 >> /etc/hosts"
sleep 60

SLAVE_EXIT=`docker-compose logs pgslave3  | tail -n5 | grep 'repmgrd terminating...' | wc -l | tr -d ' '`
if [[ "$SLAVE_EXIT" != "1" ]]; then
    echo '>>> Isolated slave should die!';
    exit 1
fi


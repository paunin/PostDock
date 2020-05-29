#!/usr/bin/env bash

docker-compose up -d pgmaster pgreplica1 pgreplica3

docker-compose exec -T pgmaster wait_local_postgres
docker-compose exec -T pgreplica1 wait_local_postgres
docker-compose exec -T pgreplica3 wait_local_postgres
sleep 10
echo ">>> Isolating pgreplica3..."
docker-compose exec pgreplica3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts && echo 1.1.1.2 pgreplica1 >> /etc/hosts"
sleep 60

replica_EXIT=`docker-compose logs pgreplica3  | tail -n5 | grep 'repmgrd terminating...' | wc -l | tr -d ' '`
if [[ "$replica_EXIT" != "1" ]]; then
    echo '>>> Isolated replica should die!';
    exit 1
fi


#!/usr/bin/env bash

docker-compose up -d pgmaster pgslave1 pgslave3

docker-compose exec  pgmaster wait_local_postgres && \
docker-compose exec  pgslave1 wait_local_postgres && \
docker-compose exec  pgslave3 wait_local_postgres && \
sleep 10

docker-compose restart pgmaster && \
docker-compose exec pgmaster wait_local_postgres

docker-compose exec  pgmaster /usr/local/bin/cluster/healthcheck/is_major_master.sh
if [[ "$?" == 1 ]];then
    echo "After fast restart master should be the same!"
    exit 1
fi

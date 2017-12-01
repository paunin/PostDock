#!/usr/bin/env bash

docker-compose up -d pgmaster pgslave1 pgslave2 pgslave3 pgpool

docker-compose exec -T pgmaster wait_local_postgres
docker-compose exec -T pgslave1 wait_local_postgres
docker-compose exec -T pgslave2 wait_local_postgres
docker-compose exec -T pgslave3 wait_local_postgres

sleep 20
docker-compose kill pgmaster

# Generate some load
for i in `seq 1 50`; do
  docker-compose exec -T pgpool bash -c 'PGCONNECT_TIMEOUT=10 PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h 127.0.0.1 template1 -c "SELECT 1;"' ;
done

#Calculate delay for node to be marked as down
# health_check_period + health_check_max_retries*(health_check_timeout + health_check_retry_delay)
# 30 + 5 * (10 + 5) = 105 (+ some time)
sleep 180

MASTER_IS_OUT=`docker-compose exec -T pgpool bash -c 'PGCONNECT_TIMEOUT=10 PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h 127.0.0.1 template1 -c "show pool_nodes"' | grep pgmaster | awk -F"|" '{print $4}' | grep 'down\|3' | wc -l | tr -d ' '`
if [[ "$MASTER_IS_OUT" != "1" ]]; then
    echo ">>> Master should be removed from pgpool!"
    exit 1;
fi

NEW_NODE_IS_MASTER=`docker-compose exec -T pgpool bash -c 'PGCONNECT_TIMEOUT=10 PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h 127.0.0.1 template1 -c "show pool_nodes"' | grep primary | grep -v pgmaster | wc -l | tr -d ' '`
if [[ "$NEW_NODE_IS_MASTER" != "1" ]]; then
    echo ">>> New master should exist in pgpool!"
    exit 2;
fi
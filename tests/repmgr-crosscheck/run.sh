#!/usr/bin/env bash
# https://github.com/paunin/PostDock/issues/225
docker-compose up -d pgmaster pgslave1 pgslave3
set -e

docker-compose exec -T pgmaster wait_local_postgres
docker-compose exec -T pgslave1 wait_local_postgres
docker-compose exec -T pgslave3 wait_local_postgres
sleep 10

# Result matrix should look like this(5 rows, 3 rows with stars but with no question marks):
#
#  Name | Id |  1 |  2 |  4 
# ------+----+----+----+----
# node1 |  1 |  * |  * |  * 
# node2 |  2 |  * |  * |  * 
# node4 |  4 |  * |  * |  * 

for CONTAINER in "pgmaster" "pgslave1" "pgslave3"; do
    echo "Checking CONTAINER=$CONTAINER"
    UNKNOWN_NUMBER=`docker-compose exec $CONTAINER bash -c 'gosu postgres repmgr cluster crosscheck 2>/dev/null' | grep -v '?' | grep '*' | wc -l | tr -d ' '`
    if [[ "3" != "$UNKNOWN_NUMBER" ]]; then
        echo ">>> CrossCheck failed for CONTAINER=$CONTAINER (UNKNOWN_NUMBER=$UNKNOWN_NUMBER)"
        exit 1
    fi
done




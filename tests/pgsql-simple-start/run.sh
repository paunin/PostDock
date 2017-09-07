#!/usr/bin/env bash
docker-compose up -d pgmaster pgslave1

docker-compose exec  -T pgmaster wait_local_postgres
docker-compose exec  -T pgslave1 wait_local_postgres
docker-compose exec  -T pgmaster gosu postgres psql -c "CREATE TABLE check_table(id int);"
docker-compose exec  -T pgmaster gosu postgres psql -c "INSERT INTO check_table VALUES(1),(2);"
sleep 1
COUNT_ROWS=`docker-compose exec -T pgslave1 gosu postgres psql -tAc "SELECT COUNT(*) FROM check_table;"`

echo ">>> Count rows: $COUNT_ROWS"
if [[ "$COUNT_ROWS" == "2" ]]; then
    RESULT="0"
else
    RESULT="1"
fi

exit "$RESULT"
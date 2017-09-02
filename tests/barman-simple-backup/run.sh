#!/bin/bash
docker-compose down -v && docker-compose build && docker-compose up -d pgmaster backup
docker-compose exec  -T pgmaster wait_local_postgres

echo ">>> Create a test table and fill some data"
docker-compose exec pgmaster psql -U postgres monkey_db -c " create table t (time timestamp);";
for i in `seq 1 15`; do
  sleep 1
  docker-compose exec -T pgmaster psql -U postgres monkey_db -c "insert into t values(now());";
done
sleep 10
echo ">>> Make a backup"
docker-compose exec -T backup barman switch-xlog --force --archive all
docker-compose exec -T backup barman backup all

NUM_BACKUPS=`docker-compose exec -T backup barman list-backup all | grep -v 'DEBUG:' | wc -l | tr -d ' '`;

echo ">>> Number of backups: $NUM_BACKUPS"
if [[ "$NUM_BACKUPS" == "0" ]]; then
    echo '>>>>>> Should have more then 0 backups!'
    exit 1
fi

echo ">>> Latest backup..."
docker-compose exec -T backup barman show-backup pg_cluster latest

#!/bin/bash
set -e

echo ""
echo "Create a test table and fill some data"
echo ""
docker-compose exec pgmaster psql -U postgres monkey_db -c "drop table t;" || echo 'nothing to delete';
docker-compose exec pgmaster psql -U postgres monkey_db -c " create table t (time timestamp);";
for i in `seq 1 15`; do 
  docker-compose exec pgmaster psql -U postgres monkey_db -c "insert into t values(now());";
done
docker-compose exec pgslave1 psql -U postgres monkey_db -c "select count(*) from t;"

echo ""
echo "Make a backup"
echo ""
docker-compose exec backup barman switch-xlog --force --archive all
docker-compose exec backup barman backup all

echo ""
echo "Add some more data to test PITR"
echo ""
for i in `seq 1 15`; do docker-compose exec pgmaster psql -U postgres monkey_db -c "insert into t values(now());"; done;
docker-compose exec backup barman switch-xlog --force --archive all

echo ""
echo "Current state..."
echo ""
docker-compose exec pgslave1 psql -U postgres monkey_db -c "select * from t;"
docker-compose exec backup barman list-backup all
docker-compose exec backup barman show-backup pg_cluster latest



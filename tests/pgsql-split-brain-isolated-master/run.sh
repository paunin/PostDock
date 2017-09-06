#!/usr/bin/env bash

docker-compose up -d pgmaster pgslave1 pgslave3

docker-compose exec  -T pgmaster wait_local_postgres
docker-compose exec  -T pgslave1 wait_local_postgres
docker-compose exec  -T pgslave3 wait_local_postgres
sleep 10

docker-compose exec -T pgslave1 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"
docker-compose exec -T pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"
docker-compose exec -T pgmaster bash -c "echo 1.1.1.1 pgslave1 >> /etc/hosts && echo 1.1.1.1 pgslave3 >> /etc/hosts "

sleep 60

echo ">>> Isolated Master:" && \
docker-compose exec -T pgmaster bash -c "gosu postgres repmgr cluster show" && \
echo ">>> Isolated Standbys:" && \
docker-compose exec -T pgslave1 bash -c "gosu postgres repmgr cluster show" && \
docker-compose exec -T pgslave3 bash -c "gosu postgres repmgr cluster show"

docker-compose exec  -T pgmaster /usr/local/bin/cluster/healthcheck/is_major_master.sh
if [[ "$?" == 0 ]];then
    echo "After isolation master should not feel like major master!"
    exit 1
fi

docker-compose exec -T pgmaster bash -c "cat /etc/hosts | grep -v pgslave1 | grep -v pgslave3 > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"
docker-compose exec -T pgslave1 bash -c "cat /etc/hosts | grep -v pgmaster > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"
docker-compose exec -T pgslave3 bash -c "cat /etc/hosts | grep -v pgmaster  > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"

docker-compose exec  -T pgmaster /usr/local/bin/cluster/healthcheck/is_major_master.sh
if [[ "$?" == 0 ]];then
    echo "After restored connectivity master should not feel like major master!"
    exit 2
fi

echo ">>> Isolated Master:" && \
docker-compose exec -T pgmaster bash -c "gosu postgres repmgr cluster show" && \
echo ">>> Isolated Standbys:" && \
docker-compose exec -T pgslave1 bash -c "gosu postgres repmgr cluster show" && \
docker-compose exec -T pgslave3 bash -c "gosu postgres repmgr cluster show"
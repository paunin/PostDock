#!/usr/bin/env bash

docker-compose build && docker-compose up -d
sleep 60

docker-compose exec pgslave1 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"
docker-compose exec pgslave3 bash -c "echo 1.1.1.1 pgmaster >> /etc/hosts"
docker-compose exec pgmaster bash -c "echo 1.1.1.1 pgslave1 >> /etc/hosts && echo 1.1.1.1 pgslave3 >> /etc/hosts "

sleep 60

echo "Isolated Master:" && \
docker-compose exec pgmaster bash -c "gosu postgres repmgr cluster show" && \
echo "Isolated Standbys:" && \
docker-compose exec pgslave1 bash -c "gosu postgres repmgr cluster show" && \
docker-compose exec pgslave3 bash -c "gosu postgres repmgr cluster show"

docker-compose logs -f
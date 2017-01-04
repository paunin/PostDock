#!/usr/bin/env bash

docker-compose exec pgmaster bash -c "cat /etc/hosts | grep -v pgslave1 | grep -v pgslave3 > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"
docker-compose exec pgslave1 bash -c "cat /etc/hosts | grep -v pgmaster > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"
docker-compose exec pgslave3 bash -c "cat /etc/hosts | grep -v pgmaster  > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts"
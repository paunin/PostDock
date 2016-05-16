#!/usr/bin/env bash

docker kill `docker ps -aq`
docker rm `docker ps -aq`
docker rmi `docker images -aq`
docker volume rm `docker volume ls -q`

#docker-machine restart
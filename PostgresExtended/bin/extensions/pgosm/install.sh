#!/usr/bin/env bash

apt-get install -y make build-essential
cd /tmp && \
    wget -qO-  https://github.com/openstreetmap/openstreetmap-website/archive/master.tar.gz | tar xz

cd /tmp/openstreetmap-website-master/db/functions 
make libpgosm.so 
cp libpgosm.so /usr/lib/postgresql/$PG_MAJOR/lib

apt-get remove -y make build-essential

rm -rf /tmp/openstreetmap-website-master/
#!/usr/bin/env bash

apt-get install -y make build-essential
cd /tmp && \
    wget -qO-  https://github.com/openstreetmap/openstreetmap-website/archive/e4b94f4e5ef195dd5743ab3a510caecb7525a3b7.tar.gz | tar xz

cd /tmp/openstreetmap-website-*/db/functions 
make libpgosm.so 
cp libpgosm.so /usr/lib/postgresql/$PG_MAJOR/lib

apt-get remove -y make build-essential
cd /
rm -rf /tmp/openstreetmap-website-master/
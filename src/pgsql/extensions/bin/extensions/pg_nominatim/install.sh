#!/usr/bin/env bash

apt-get install -y cmake make build-essential g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev \
    libbz2-dev libpq-dev libproj-dev
cd /tmp && \
    wget -qO- https://nominatim.org/release/Nominatim-3.1.0.tar.bz2 | tar xvj

cd /tmp/Nominatim-3.1.0 && mkdir build && cd build
cmake ..

cd ./module && make
cp nominatim.so /usr/lib/postgresql/$PG_MAJOR/lib

apt-get remove -y cmake make build-essential g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev \
    libbz2-dev libpq-dev libproj-dev
cd /
rm -rf /tmp/Nominatim-3.1.0

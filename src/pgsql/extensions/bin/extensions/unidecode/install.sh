#!/usr/bin/env bash

apt-get install -y build-essential unzip

cd /tmp && \
    wget http://api.pgxn.org/dist/unidecode/0.0.5/unidecode-0.0.5.zip

unzip unidecode-0.0.5.zip 
cd unidecode-0.0.5
sed -i 's|0.0.4|0.0.5|g' unidecode.control
make && make install

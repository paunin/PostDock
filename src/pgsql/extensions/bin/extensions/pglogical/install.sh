#!/usr/bin/env bash
DEB_VERSION=`grep "VERSION=" /etc/os-release |awk -F= {' print $2'}|sed s/\"//g |sed s/[0-9]//g | sed s/\)$//g |sed s/\(//g`

echo "deb [arch=amd64] http://packages.2ndquadrant.com/pglogical/apt/ ${DEB_VERSION}-2ndquadrant main" > /etc/apt/sources.list.d/2ndquadrant.list
wget --quiet -O - http://packages.2ndquadrant.com/pglogical/apt/AA7A6805.asc | apt-key add - 
apt-get update

apt-get install -y --no-install-recommends postgresql-${PG_MAJOR}-pglogical
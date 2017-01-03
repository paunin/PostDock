#!/usr/bin/env bash
set -e

echo '>>> TUNING UP SSH CLIENT...'
cat /home/postgres/.ssh/id_rsa.pub >> /home/postgres/.ssh/authorized_keys
chown -R postgres:postgres /home/postgres
gosu postgres chmod 600 -R /home/postgres/.ssh/id_rsa


echo '>>> STARTING SSH SERVER...'
/usr/sbin/sshd -D &

echo '>>> STARTING POSTGRES...'
/usr/local/bin/cluster/entrypoint.sh postgres
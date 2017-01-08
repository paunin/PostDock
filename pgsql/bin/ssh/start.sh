#!/usr/bin/env bash

echo '>>> Tuning up sshd...'
cat /home/postgres/.ssh/id_rsa.pub >> /home/postgres/.ssh/authorized_keys
chown -R postgres:postgres /home/postgres
gosu postgres chmod 600 -R /home/postgres/.ssh/id_rsa

echo '>>> Starting...'
/usr/sbin/sshd -D &
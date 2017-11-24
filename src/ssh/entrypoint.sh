#!/usr/bin/env bash

set -e

chown -R postgres:postgres /home/postgres
chmod 600 -R /home/postgres/.ssh/id_rsa

if [[ "$SSH_ENABLE" == "1" ]]; then
    echo '>>> TUNING UP SSH CLIENT...'

    mkdir -p /var/run/sshd && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
    echo "export VISIBLE=now" >> /etc/profile

    cat /home/postgres/.ssh/id_rsa.pub >> /home/postgres/.ssh/authorized_keys

    echo '>>> STARTING SSH SERVER...'
    /usr/sbin/sshd 2>&1
else
    echo ">>> SSH is not enabled!"
fi

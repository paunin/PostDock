#!/usr/bin/env bash

set -e

if [[ "$SSH_ENABLE" == "1" ]]; then
    echo '>>> TUNING UP SSH CLIENT...'

    mkdir /var/run/sshd && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
    echo "export VISIBLE=now" >> /etc/profile

    cat /home/postgres/.ssh/id_rsa.pub >> /home/postgres/.ssh/authorized_keys
    chown -R postgres:postgres /home/postgres
    chmod 600 -R /home/postgres/.ssh/id_rsa

    echo '>>> STARTING SSH SERVER...'
    /usr/sbin/sshd -D &
else
    echo ">>> SSH is not enabled!"
fi
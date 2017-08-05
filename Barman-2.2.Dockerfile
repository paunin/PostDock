FROM debian:jessie

ARG BARMAN_VERSION=2.2-1.pgdg80+1
ARG DOCKERIZE_VERSION=v0.2.0
RUN  apt-get update && \
     apt-get install -y wget libffi-dev libssl-dev  && \
     wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - && \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
     apt-get update && \
     apt-get install -y barman=$BARMAN_VERSION

RUN  wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
     tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ENV UPSTREAM_CONFIG_FILE /etc/barman.d/upstream.conf 
ENV REPLICATION_USER replication_user
ENV REPLICATION_PASSWORD replication_pass
ENV REPLICATION_PORT 5432
ENV POSTGRES_CONNECTION_TIMEOUT 20
ENV REPLICATION_SLOT_NAME barman_the_backupper
ENV WAIT_UPSTREAM_TIMEOUT 60
ENV INITIAL_BACKUP_DELAY 60
ENV BARMAN_BACKUP_DIR /var/backups

# REQUIRED ENV VARS:
# ENV REPLICATION_HOST localhost
# ENV POSTGRES_USER postgres
# ENV POSTGRES_PASSWORD password
# ENV POSTGRES_DB monkey_db


COPY ./barman/configs/barman.conf /etc/barman.conf
COPY ./barman/configs/upstream.conf $UPSTREAM_CONFIG_FILE
COPY ./barman/bin /usr/local/bin/barman_docker
RUN chmod +x /usr/local/bin/barman_docker/* && ls /usr/local/bin/barman_docker

CMD /usr/local/bin/barman_docker/entrypoint.sh
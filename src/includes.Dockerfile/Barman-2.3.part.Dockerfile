FROM golang:1.8-jessie

ARG BARMAN_VERSION={{ BARMAN_VERSION }}
ARG PG_CLIENT_VERSION=9.6.\*
# grab gosu for easy step-down from root
ARG GOSU_VERSION=1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true 

RUN  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - && \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
     apt-get update && \
     apt-get install -y libffi-dev libssl-dev postgresql-client-9.6=$PG_CLIENT_VERSION barman=$BARMAN_VERSION openssh-server

RUN apt-get -y install cron
ADD barman/crontab /etc/cron.d/barman
RUN rm -f /etc/cron.daily/*

RUN groupadd -r postgres --gid=999 && useradd -r -g postgres -d /home/postgres --uid=999 postgres

ENV UPSTREAM_NAME pg_cluster
ENV UPSTREAM_CONFIG_FILE /etc/barman.d/upstream.conf 
ENV REPLICATION_USER replication_user
ENV REPLICATION_PASSWORD replication_pass
ENV REPLICATION_PORT 5432
ENV POSTGRES_CONNECTION_TIMEOUT 20
ENV REPLICATION_SLOT_NAME barman_the_backupper
ENV WAIT_UPSTREAM_TIMEOUT 60
ENV SSH_ENABLE 0
ENV NOTVISIBLE "in users profile"
ENV BACKUP_SCHEDULE "0 0 * * *"
ENV BACKUP_RETENTION_DAYS "30"
ENV BACKUP_DIR /var/backups

# REQUIRED ENV VARS:
# ENV REPLICATION_HOST localhost
# ENV POSTGRES_USER postgres
# ENV POSTGRES_PASSWORD password
# ENV POSTGRES_DB monkey_db

EXPOSE 22

COPY ./ssh /home/postgres/.ssh
RUN chown -R postgres:postgres /home/postgres
COPY ./barman/configs/barman.conf /etc/barman.conf
COPY ./barman/configs/upstream.conf $UPSTREAM_CONFIG_FILE
COPY ./barman/bin /usr/local/bin/barman_docker
RUN chmod +x /usr/local/bin/barman_docker/* && ls /usr/local/bin/barman_docker

COPY ./barman/metrics /go
RUN cd /go && go build /go/main.go

VOLUME $BACKUP_DIR

CMD /usr/local/bin/barman_docker/entrypoint.sh

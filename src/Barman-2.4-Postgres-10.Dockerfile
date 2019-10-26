##########################################################################
##                         AUTO-GENERATED FILE                          ##
##########################################################################

FROM golang:1.11-stretch

# grab gosu for easy step-down from root
ARG GOSU_VERSION=1.11
RUN set -eux \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates libpq5 wget gnupg2 gosu && rm -rf /var/lib/apt/lists/*  && \
	gosu nobody true

COPY ./dockerfile/bin /usr/local/bin/dockerfile
RUN chmod -R +x /usr/local/bin/dockerfile && ln -s /usr/local/bin/dockerfile/functions/* /usr/local/bin/

RUN  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - && \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
     apt-get update && \
     apt-get install -y libffi-dev libssl-dev openssh-server

RUN  apt-get install -y postgresql-client-10


RUN install_deb_pkg "http://atalia.postgresql.org/morgue/b/barman/barman_2.4-1.pgdg90+1_all.deb"

RUN apt-get -y install cron
ADD barman/crontab /etc/cron.d/barman
RUN rm -f /etc/cron.daily/*

RUN groupadd -r postgres --gid=999 && useradd -r -g postgres -d /home/postgres --uid=999 postgres
RUN mkdir /home/postgres && chown postgres:postgres /home/postgres

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

COPY ./ssh /tmp/.ssh
RUN mv /tmp/.ssh/sshd_start /usr/local/bin/sshd_start && chmod +x /usr/local/bin/sshd_start
COPY ./barman/configs/barman.conf /etc/barman.conf
COPY ./barman/configs/upstream.conf $UPSTREAM_CONFIG_FILE
COPY ./barman/bin /usr/local/bin/barman_docker
RUN chmod +x /usr/local/bin/barman_docker/* && ls /usr/local/bin/barman_docker

COPY ./barman/metrics /go
RUN cd /go && go build /go/main.go

VOLUME $BACKUP_DIR

CMD /usr/local/bin/barman_docker/entrypoint.sh

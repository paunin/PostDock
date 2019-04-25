
##########################################################################
##                         AUTO-GENERATED FILE                          ##
##               BUILD_NUMBER=Thu 25 Apr 2019 15:26:29 +08              ##
##########################################################################

FROM debian:stretch
ARG DOCKERIZE_VERSION=v0.2.0

RUN groupadd -r postgres --gid=999 && useradd -r -g postgres -d /home/postgres  --uid=999 postgres

# grab gosu for easy step-down from root
ARG GOSU_VERSION=1.11
RUN set -eux \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget gnupg2 gosu && rm -rf /var/lib/apt/lists/*  && \
	gosu nobody true

RUN  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - && \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
     apt-get update

RUN  apt-get install -y libffi-dev libssl-dev openssh-server

RUN  apt-get install -y postgresql-client-9.6



RUN TEMP_DEB="$(mktemp)" && \
    wget -O "$TEMP_DEB" "http://atalia.postgresql.org/morgue/p/pgpool2/libpgpool0_3.3.4-1.pgdg70+1_amd64.deb" && \
    (dpkg -i "$TEMP_DEB" || true) && apt-mark hold libpgpool0 && apt-get install -y -f && rm -f "$TEMP_DEB"

RUN TEMP_DEB="$(mktemp)" && \
    wget -O "$TEMP_DEB" "http://atalia.postgresql.org/morgue/p/pgpool2/pgpool2_3.3.4-1.pgdg70+1_amd64.deb" && \
    (dpkg -i "$TEMP_DEB" || true) && apt-mark hold pgpool2 && apt-get install -y -f && rm -f "$TEMP_DEB"

RUN  wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
     tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY ./ssh /home/postgres/.ssh
COPY ./pgpool/bin /usr/local/bin/pgpool
COPY ./pgpool/configs /var/pgpool_configs

RUN chmod +x -R /usr/local/bin/pgpool

ENV CHECK_USER replication_user
ENV CHECK_PASSWORD replication_pass
ENV CHECK_PGCONNECT_TIMEOUT 10
ENV WAIT_BACKEND_TIMEOUT 120
ENV REQUIRE_MIN_BACKENDS 0
ENV SSH_ENABLE 0
ENV NOTVISIBLE "in users profile"

ENV CONFIGS_DELIMITER_SYMBOL ,
ENV CONFIGS_ASSIGNMENT_SYMBOL :
                                #CONFIGS_DELIMITER_SYMBOL and CONFIGS_ASSIGNMENT_SYMBOL are used to parse CONFIGS variable
                                # if CONFIGS_DELIMITER_SYMBOL=| and CONFIGS_ASSIGNMENT_SYMBOL=>, valid configuration string is var1>val1|var2>val2


EXPOSE 22
EXPOSE 5432
EXPOSE 9898

HEALTHCHECK --interval=1m --timeout=10s --retries=5 \
  CMD /usr/local/bin/pgpool/has_write_node.sh

CMD ["/usr/local/bin/pgpool/entrypoint.sh"]

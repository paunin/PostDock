##########################################################################
##                         AUTO-GENERATED FILE                          ##
##########################################################################

FROM debian:stretch
ARG DOCKERIZE_VERSION=v0.2.0

RUN groupadd -r postgres --gid=999 && useradd -r -g postgres -d /home/postgres  --uid=999 postgres

# grab gosu for easy step-down from root
ARG GOSU_VERSION=1.11
RUN set -eux \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget gnupg2 libffi-dev openssh-server gosu && rm -rf /var/lib/apt/lists/*  && \
	gosu nobody true

COPY ./dockerfile/bin /usr/local/bin/dockerfile
RUN chmod -R +x /usr/local/bin/dockerfile && ln -s /usr/local/bin/dockerfile/functions/* /usr/local/bin/

RUN  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add - && \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
     apt-get update

RUN  apt-get install -y postgresql-client-11


RUN install_deb_pkg "http://launchpadlibrarian.net/160156688/libmemcached10_1.0.8-1ubuntu2_amd64.deb" "libmemcached10"
RUN install_deb_pkg "http://security-cdn.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u11_amd64.deb" "libssl1.0.0"
RUN install_deb_pkg "http://atalia.postgresql.org/morgue/p/pgpool2/libpgpool0_3.7.5-2.pgdg90+1_amd64.deb" "libpgpool0"
RUN install_deb_pkg "http://atalia.postgresql.org/morgue/p/pgpool2/pgpool2_3.7.5-2.pgdg90+1_amd64.deb" "pgpool2"

RUN  wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
     tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

COPY ./ssh /tmp/.ssh
RUN mv /tmp/.ssh/sshd_start /usr/local/bin/sshd_start && chmod +x /usr/local/bin/sshd_start
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

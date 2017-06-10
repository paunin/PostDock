FROM debian:jessie
ARG DOCKERIZE_VERSION=v0.2.0
ARG POSTGRES_CLIENT_VERSION=9.4
ARG PGPOOL_VERSION=3.6.4

RUN echo deb http://debian.xtdv.net/debian jessie main > /etc/apt/sources.list && apt-get update && \
    apt-get install -y postgresql-client-$POSTGRES_CLIENT_VERSION libffi-dev libssl-dev wget gcc libpq-dev make

RUN  wget http://www.pgpool.net/download.php?f=pgpool-II-$PGPOOL_VERSION.tar.gz -O pgpool-II-$PGPOOL_VERSION.tar.gz && \
    tar -zxvf pgpool-II-$PGPOOL_VERSION.tar.gz && rm pgpool-II-$PGPOOL_VERSION.tar.gz  && \
    cd pgpool-II-$PGPOOL_VERSION && ./configure && make && make install && cd .. && rm -rf pgpool-II-$PGPOOL_VERSION.tar.gz && \

    wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz


RUN mv /usr/local/bin/pgpool /usr/bin/pgpool && \
    mkdir -p /var/run/postgresql/ /var/log/postgresql/

RUN apt-get install -y  libpcap-dev

COPY ./pgpool/bin /usr/local/bin/pgpool
COPY ./pgpool/configs /var/pgpool_configs

RUN chmod +x -R /usr/local/bin/pgpool

ENV CHECK_USER replication_user
ENV CHECK_PASSWORD replication_pass
ENV CHECK_PGCONNECT_TIMEOUT 10
ENV WAIT_BACKEND_TIMEOUT 120
ENV REQUIRE_MIN_BACKENDS 0

HEALTHCHECK --interval=1m --timeout=10s --retries=5 \
  CMD /usr/local/bin/pgpool/has_write_node.sh

CMD ["/usr/local/bin/pgpool/entrypoint.sh"]
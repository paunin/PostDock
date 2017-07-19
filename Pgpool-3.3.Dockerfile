FROM debian:jessie
ARG DOCKERIZE_VERSION=v0.2.0
ARG POSTGRES_CLIENT_VERSION=9.4
ARG PGPOOL_VERSION=3.3.4-1

 RUN apt-get update && \
     apt-get install -y postgresql-client-$POSTGRES_CLIENT_VERSION libffi-dev libssl-dev pgpool2=$PGPOOL_VERSION wget && \
     wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
     && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

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
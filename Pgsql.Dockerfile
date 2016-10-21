FROM postgres:9.5
RUN echo deb http://debian.xtdv.net/debian jessie main > /etc/apt/sources.list && apt-get update

RUN apt-get install -y repmgr

ENV CLUSTER_NAME pg_cluster
# special repmgr db for cluster info
ENV REPLICATION_DB replication_db
ENV REPLICATION_USER replication_user
ENV REPLICATION_PASSWORD replication_pass

ENV REPLICATION_PRIMARY_PORT 5432

ENV INITIAL_NODE_TYPE standby
# CLUSTER_NODE_NETWORK_NAME null # (default: hostanme of the node)

#### Advanced options ####
ENV CONNECT_TIMEOUT 2
ENV RECONNECT_ATTEMPTS 3
ENV RECONNECT_INTERVAL 5
ENV MASTER_RESPONSE_TIMEOUT 20
ENV LOG_LEVEL INFO
# Clean $PGDATA directory before start
ENV FORCE_CLEAN 0

COPY ./bin /usr/local/bin/cluster
RUN chmod -R +x /usr/local/bin/cluster && \
    ln -s /usr/local/bin/cluster/wait_db.sh /usr/local/bin/wait_db

COPY ./configs /var/cluster_configs

ENTRYPOINT ["/usr/local/bin/cluster/entrypoint.sh"]
CMD ["postgres"]
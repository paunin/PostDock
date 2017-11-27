FROM postgres:{{ POSTGRES_VERSION }}

RUN apt-get update --fix-missing && \
    apt-get install -y postgresql-server-dev-$PG_MAJOR wget openssh-server barman-cli

#<<< Hack to support initial version of Repmgr (https://github.com/paunin/PostDock/issues/97)
RUN TEMP_DEB="$(mktemp)" && \
    wget -O "$TEMP_DEB" "http://atalia.postgresql.org/morgue/r/repmgr/repmgr-common_3.3.2-1.pgdg80%2b1_all.deb" && \
    dpkg -i "$TEMP_DEB" && rm -f "$TEMP_DEB" && \
    TEMP_DEB="$(mktemp)" && \
    wget -O "$TEMP_DEB" "http://atalia.postgresql.org/morgue/r/repmgr/postgresql-$PG_MAJOR-repmgr_3.3.2-1.pgdg80%2b1_amd64.deb" && \
    dpkg -i "$TEMP_DEB" && apt-get install -f && rm -f "$TEMP_DEB"
# >>> Hack

# Inherited variables
# ENV POSTGRES_PASSWORD monkey_pass
# ENV POSTGRES_USER monkey_user
# ENV POSTGRES_DB monkey_db

# Name of the cluster you want to start
ENV CLUSTER_NAME pg_cluster

# special repmgr db for cluster info
ENV REPLICATION_DB replication_db
ENV REPLICATION_USER replication_user
ENV REPLICATION_PASSWORD replication_pass
ENV REPLICATION_PRIMARY_PORT 5432


# Host for replication (REQUIRED, NO DEFAULT)
# ENV REPLICATION_PRIMARY_HOST

# Integer number of node (REQUIRED, NO DEFAULT)
# ENV NODE_ID 1

# Node name (REQUIRED, NO DEFAULT)
# ENV NODE_NAME node1

# (default: `hostname` of the node)
# ENV CLUSTER_NODE_NETWORK_NAME null

# priority on electing new master
ENV NODE_PRIORITY 100

# ENV CONFIGS "listen_addresses:'*'"
                                    # in format variable1:value1[,variable2:value2[,...]]
                                    # used for pgpool.conf file

ENV PARTNER_NODES ""
                    # List (comma separated) of all nodes in the cluster, it allows master to be adaptive on restart
                    # (can act as a new standby if new master has been already elected)

ENV MASTER_ROLE_LOCK_FILE_NAME $PGDATA/master.lock
                                                   # File will be put in $MASTER_ROLE_LOCK_FILE_NAME when:
                                                   #    - node starts as a primary node/master
                                                   #    - node promoted to a primary node/master
                                                   # File does not exist
                                                   #    - if node starts as a standby
ENV STANDBY_ROLE_LOCK_FILE_NAME $PGDATA/standby.lock
                                                  # File will be put in $STANDBY_ROLE_LOCK_FILE_NAME when:
                                                  #    - event repmgrd_failover_follow happened
                                                  # contains upstream NODE_ID
                                                  # that basically used when standby changes upstream node set by default
ENV REPMGR_WAIT_POSTGRES_START_TIMEOUT 90
                                            # For how long in seconds repmgr will wait for postgres start on current node
                                            # Should be big enough to perform post replication start which might take from a minute to a few
ENV USE_REPLICATION_SLOTS 1
                                # Use replication slots to make sure that WAL files will not be removed without beein synced to replicas
                                # Recomended(not required though) to put 0 for replicas of the second and deeper levels
ENV CLEAN_OVER_REWIND 0
                        # Clean $PGDATA directory before start standby and not try to rewind
ENV SSH_ENABLE 0
                        # If you need SSH server running on the node

#### Advanced options ####
ENV REPMGR_PID_FILE /tmp/repmgrd.pid
ENV WAIT_SYSTEM_IS_STARTING 5
ENV STOPPING_LOCK_FILE /tmp/stop.pid
ENV REPLICATION_LOCK_FILE /tmp/replication
ENV STOPPING_TIMEOUT 15
ENV CONNECT_TIMEOUT 2
ENV RECONNECT_ATTEMPTS 3
ENV RECONNECT_INTERVAL 5
ENV MASTER_RESPONSE_TIMEOUT 20
ENV LOG_LEVEL INFO
ENV CHECK_PGCONNECT_TIMEOUT 10
ENV REPMGR_SLOT_NAME_PREFIX repmgr_slot_

COPY ./pgsql/bin /usr/local/bin/cluster
RUN chmod -R +x /usr/local/bin/cluster
RUN ln -s /usr/local/bin/cluster/functions/* /usr/local/bin/
COPY ./pgsql/configs /var/cluster_configs

ENV NOTVISIBLE "in users profile"

COPY ./ssh /home/postgres/.ssh
RUN chown -R postgres:postgres /home/postgres

EXPOSE 22
EXPOSE 5432

VOLUME /var/lib/postgresql/data
USER root

CMD ["/usr/local/bin/cluster/entrypoint.sh"]

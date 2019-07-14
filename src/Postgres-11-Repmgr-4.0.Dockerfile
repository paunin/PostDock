##########################################################################
##                         AUTO-GENERATED FILE                          ##
##########################################################################

FROM postgres:11

RUN apt-get update --fix-missing && \
    apt-get install -y postgresql-server-dev-$PG_MAJOR wget openssh-server barman-cli

COPY ./dockerfile/bin /usr/local/bin/dockerfile
RUN chmod -R +x /usr/local/bin/dockerfile && ln -s /usr/local/bin/dockerfile/functions/* /usr/local/bin/


RUN install_deb_pkg "http://atalia.postgresql.org/morgue/r/repmgr/repmgr-common_4.0.6-2.pgdg+1_all.deb" 
RUN install_deb_pkg "http://atalia.postgresql.org/morgue/r/repmgr/postgresql-$PG_MAJOR-repmgr_4.0.6-2.pgdg+1_amd64.deb" 

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

# Integer number of node (NO DEFAULT) 
# ENV NODE_ID 1
                # if not defined, will be generated from the last number in NODE_NAME variable
                # e.g. NODE_NAME=node-1 will give node identifier 1002

# Node name (REQUIRED, NO DEFAULT)
# ENV NODE_NAME node-1

# (default: `hostname` of the node)
# ENV CLUSTER_NODE_NETWORK_NAME null

# priority on electing new master
ENV NODE_PRIORITY 100

ENV CONFIGS_DELIMITER_SYMBOL ,
ENV CONFIGS_ASSIGNMENT_SYMBOL :
                                #CONFIGS_DELIMITER_SYMBOL and CONFIGS_ASSIGNMENT_SYMBOL are used to parse CONFIGS variable
                                # if CONFIGS_DELIMITER_SYMBOL=| and CONFIGS_ASSIGNMENT_SYMBOL=>, valid configuration string is var1>val1|var2>val2

ENV REPMGR_MAJOR 4
ENV REPMGR_NODES_TABLE nodes
ENV REPMGR_NODE_ID_COLUMN node_id
ENV REPMGR_NODE_NAME_COLUMN node_name
ENV REPMGR_CLUSTER_SHOW_MASTER_PATTERN primary
ENV REPMGR_SHOW_NODES_TABLE show_nodes
ENV REPMGR_NODE_ID_PARAM_NAME node_id
ENV REPMGR_LOG_LEVEL_PARAM_NAME log_level
ENV REPMGR_MASTER_RESPONSE_TIMEOUT_PARAM_NAME async_query_timeout

# ENV CONFIGS "listen_addresses:'*'"
                                    # in format variable1:value1[,variable2:value2[,...]] if CONFIGS_DELIMITER_SYMBOL=, and CONFIGS_ASSIGNMENT_SYMBOL=:
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
ENV REPMGR_DEGRADED_MONITORING_TIMEOUT 5
ENV REPMGR_PID_FILE /tmp/repmgrd.pid
ENV STOPPING_LOCK_FILE /tmp/stop.pid
ENV MASTER_SYNC_LOCK_FILE /tmp/replication
ENV STOPPING_TIMEOUT 5
ENV CONNECT_TIMEOUT 2
ENV RECONNECT_ATTEMPTS 3
ENV RECONNECT_INTERVAL 5
ENV MASTER_RESPONSE_TIMEOUT 20
ENV LOG_LEVEL INFO
ENV CHECK_PGCONNECT_TIMEOUT 10
ENV REPMGR_SLOT_NAME_PREFIX repmgr_slot_
ENV LAUNCH_RECOVERY_CHECK_INTERVAL 30

COPY ./pgsql/bin /usr/local/bin/cluster
RUN chmod -R +x /usr/local/bin/cluster
RUN ln -s /usr/local/bin/cluster/functions/* /usr/local/bin/
COPY ./pgsql/configs /var/cluster_configs

ENV NOTVISIBLE "in users profile"

COPY ./ssh /tmp/.ssh
RUN mv /tmp/.ssh/sshd_start /usr/local/bin/sshd_start && chmod +x /usr/local/bin/sshd_start

EXPOSE 22
EXPOSE 5432

VOLUME /var/lib/postgresql/data
USER root

CMD ["/usr/local/bin/cluster/entrypoint.sh"]

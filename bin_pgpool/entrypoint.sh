#!/bin/bash

echo ">>> Waiting for $PGPOOL_START_DELAY seconds to start pgpool"
sleep $PGPOOL_START_DELAY


echo ">>> Adding user $PCP_USER for PCP"
echo "$PCP_USER:`pg_md5 $PCP_PASSWORD`" >> /etc/pgpool2/pcp.conf
cp -f /var/pgpool_configs/pgpool.conf /etc/pgpool2/


echo ">>> Adding users for md5 auth"
IFS=',' read -ra USER_PASSES <<< "$DB_USERS"
for USER_PASS in ${USER_PASSES[@]}
do
    IFS=':' read -ra USER <<< "$USER_PASS"
    pg_md5 --md5auth --username="${USER[0]}" "${USER[1]}"
done
echo "host all all 0.0.0.0/0 md5" >> /etc/pgpool2/pool_hba.conf


echo ">>> Adding backends"
IFS=',' read -ra HOSTS <<< "$BACKENDS"
for HOST in ${HOSTS[@]}
do
    IFS=':' read -ra INFO <<< "$HOST"

    NUM=""
    HOST=""
    PORT="5432"
    WEIGHT=1
    DIR="/var/lib/postgresql/data"
    FLAG="ALLOW_TO_FAILOVER"

    [[ "${INFO[0]}" != "" ]] && NUM="${INFO[0]}"
    [[ "${INFO[1]}" != "" ]] && HOST="${INFO[1]}"
    [[ "${INFO[2]}" != "" ]] && PORT="${INFO[2]}"
    [[ "${INFO[3]}" != "" ]] && WEIGHT="${INFO[3]}"
    [[ "${INFO[4]}" != "" ]] && DIR="${INFO[4]}"
    [[ "${INFO[5]}" != "" ]] && FLAG="${INFO[5]}"

    echo "
backend_hostname$NUM = '$HOST'
backend_port$NUM = $PORT
backend_weight$NUM = $WEIGHT
backend_data_directory$NUM = '$DIR'
backend_flag$NUM = '$FLAG'
" >> /etc/pgpool2/pgpool.conf

done

echo ">>> Adding user $REPLICATION_USER as check user"
echo "
sr_check_password = '$REPLICATION_PASSWORD'
sr_check_user = '$REPLICATION_USER'" >> /etc/pgpool2/pgpool.conf

echo "search_primary_node_timeout = $SEARCH_PRIMARY_NODE_TIMEOUT" >> /etc/pgpool2/pgpool.conf

rm -rf /var/run/postgresql/pgpool.pid
pgpool -n
#!/usr/bin/env bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "Warning: both $var and $fileVar are set. Getting value from $fileVar"
		unset "$var"
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

envs=(
    REPLICATION_PASSWORD
    POSTGRES_PASSWORD
)

for e in "${envs[@]}"; do
    file_env "$e"
done

REPLICATION_PASSWORD=${REPLICATION_PASSWORD:-replication_pass}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}

chown -R postgres:postgres $BACKUP_DIR

echo ">>> Checking all configurations"
[[ "$REPLICATION_HOST" != "" ]] || ( echo 'Variable REPLICATION_HOST is not set!' ;exit 1 )
[[ "$POSTGRES_USER" != "" ]] || ( echo 'Variable POSTGRES_USER is not set!' ;exit 2 )
[[ "$POSTGRES_PASSWORD" != "" ]] || ( echo 'Variable POSTGRES_PASSWORD is not set!' ;exit 3 )
[[ "$POSTGRES_DB" != "" ]] || ( echo 'Variable POSTGRES_DB is not set!' ;exit 4 )

echo ">>> Configuring barman for streaming replication"
echo "
[$UPSTREAM_NAME]
description =  'Cluster $UPSTREAM_NAME replication'
backup_method = postgres
streaming_archiver = on
streaming_archiver_name = barman_receive_wal
streaming_archiver_batch_size = 50
streaming_conninfo = host=$REPLICATION_HOST user=$REPLICATION_USER password=$REPLICATION_PASSWORD port=$REPLICATION_PORT
conninfo = host=$REPLICATION_HOST dbname=$POSTGRES_DB user=$POSTGRES_USER password=$POSTGRES_PASSWORD port=$REPLICATION_PORT connect_timeout=$POSTGRES_CONNECTION_TIMEOUT
slot_name = $REPLICATION_SLOT_NAME
backup_directory = $BACKUP_DIR
retention_policy = RECOVERY WINDOW OF $BACKUP_RETENTION_DAYS DAYS
" >> $UPSTREAM_CONFIG_FILE

echo '>>> STARTING SSH (if required)...'
sshd_start

echo '>>> SETUP BARMAN CRON'
echo ">>>>>> Backup schedule is $BACKUP_SCHEDULE"
echo "$BACKUP_SCHEDULE root barman backup all > /proc/1/fd/1 2> /proc/1/fd/2" >> /etc/cron.d/barman
chmod 0644 /etc/cron.d/barman

echo '>>> STARTING METRICS SERVER'
/go/main &

echo '>>> STARTING CRON'
env >> /etc/environment
cron -f


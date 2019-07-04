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
    DB_USERS
    PCP_PASSWORD
    CHECK_PASSWORD
)

for e in "${envs[@]}"; do
    file_env "$e"
done

DB_USERS=${PCP_PASSWORD:-}
PCP_PASSWORD=${PCP_PASSWORD:-pcp_pass}
CHECK_PASSWORD=${CHECK_PASSWORD:-replication_pass}

export CONFIG_FILE='/usr/local/etc/pgpool.conf'
export PCP_FILE='/usr/local/etc/pcp.conf'
export HBA_FILE='/usr/local/etc/pool_hba.conf'
export POOL_PASSWD_FILE='/usr/local/etc/pool_passwd'

echo '>>> STARTING SSH (if required)...'
sshd_start

## Fix for 'DETAIL: bind socket failed with error: "Address already in use"' on restart
PG_PID=/var/run/postgresql/pgpool.pid
PG_POSTGRES_PORT=/var/run/postgresql/.s.PGSQL.5432
PG_POOL_PORT=/var/run/postgresql/.s.PGSQL.9898
echo ">>> CHECKING PID FILES..."
if [ -a $PG_PID ]; then
    echo ">>>>>> Deleting $PG_PID"
    rm $PG_PID
fi
if [ -a $PG_POSTGRES_PORT ]; then
    echo ">>>>>> Deleting $PG_POSTGRES_PORT"
    rm $PG_POSTGRES_PORT
fi
if [ -a $PG_POOL_PORT ]; then
    echo ">>>>>> Deleting $PG_POOL_PORT"
    rm $PG_POOL_PORT
fi
## Fix for 'DETAIL: bind socket failed with error: "Address already in use"' on restart

echo '>>> TURNING PGPOOL...'
/usr/local/bin/pgpool/pgpool_setup.sh

echo '>>> STARTING PGPOOL...'
gosu postgres /usr/local/bin/pgpool/pgpool_start.sh
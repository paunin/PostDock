#!/usr/bin/env bash
set -e
FORCE_RECONFIGURE=1 postgres_configure

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
)

for e in "${envs[@]}"; do
    file_env "$e"
done

REPLICATION_PASSWORD=${REPLICATION_PASSWORD:-replication_pass}

# We need to create postgres user explicitly,
# see https://github.com/docker-library/postgres/commit/3f585c58df93e93b730c09a13e8904b96fa20c58
if [ ! "$POSTGRES_USER" = "postgres" ]; then
	echo ">>> Creating postgres user explicitly"
	psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE ROLE postgres LOGIN SUPERUSER"
fi

echo ">>> Creating replication user '$REPLICATION_USER'"
psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE ROLE $REPLICATION_USER WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' SUPERUSER CREATEDB  CREATEROLE INHERIT LOGIN;"

echo ">>> Creating replication db '$REPLICATION_DB'"
createdb $REPLICATION_DB -O $REPLICATION_USER

#TODO: make it more flexible, allow set of IPs
# Why db_name='replication' - https://dba.stackexchange.com/questions/82351/postgresql-doesnt-accept-replication-connection
echo "host replication $REPLICATION_USER 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf

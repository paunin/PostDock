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
)

for e in "${envs[@]}"; do
    file_env "$e"
done

REPLICATION_PASSWORD=${REPLICATION_PASSWORD:-replication_pass}

echo ">>> Setting up STOP handlers..."
for f in TERM SIGTERM QUIT SIGQUIT INT SIGINT KILL SIGKILL; do
    trap "system_stop $f" "$f"
done

echo '>>> STARTING SSH (if required)...'
sshd_start

echo '>>> STARTING POSTGRES...'
/usr/local/bin/cluster/postgres/entrypoint.sh & wait ${!}

EXIT_CODE=$?
echo ">>> Foreground processes returned code: '$EXIT_CODE'"

while [ -f /var/run/recovery.lock ]; do
    sleep 1;
done;

system_exit
exit $EXIT_CODE

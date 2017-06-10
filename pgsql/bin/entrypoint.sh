#!/usr/bin/env bash
set -e
echo ">>> Setting up STOP handlers..."
for f in TERM SIGTERM QUIT SIGQUIT INT SIGINT KILL SIGKILL; do
    trap "system_stop $f" "$f"
done

echo '>>> STARTING POSTGRES...'
/usr/local/bin/cluster/postgres/entrypoint.sh & wait ${!} || echo ">>> Foreground processes returned non zero code - $?"

if [ -f "$STOPPING_LOCK_FILE" ]; then
    ROSTGRES_STOPPING_PID=`head -1 $STOPPING_LOCK_FILE`
    echo ">>> Waiting for postgres stopping process[PID=$ROSTGRES_STOPPING_PID]"
    while kill -0 "$ROSTGRES_STOPPING_PID" 2> /dev/null; do sleep 1; done;
    echo "============ Good bye ============"
fi
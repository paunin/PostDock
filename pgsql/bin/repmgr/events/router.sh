#!/usr/bin/env bash
echo  "[REPMGR EVENT] Node id: $1; Event type: $2; Success [1|0]: $3; Time: $4;  Details: $5"

export EVENTS_SCRIPTS_FOLDER="$(dirname "$0")/execs"
EVENT_SCRIPT="$EVENTS_SCRIPTS_FOLDER/$2.sh"

if [ -f $EVENT_SCRIPT ]; then
    echo "[REPMGR EVENT] will execute script '$EVENT_SCRIPT' for the event"
    source $EVENT_SCRIPT
fi
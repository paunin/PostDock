#!/usr/bin/env bash
set -e

BAR="[REPMGR EVENT::$2]"
echo  "$BAR Node id: $1; Event type: $2; Success [1|0]: $3; Time: $4;  Details: $5"

if [[ "$3" != "1" ]];then
    echo "$BAR The event failed! No need to do anything."
    exit 1
fi

if [[ "$1" != "$(get_node_id)" ]]; then
    echo "$BAR The event did not happen on me! No need to do anything."
    exit 1
fi

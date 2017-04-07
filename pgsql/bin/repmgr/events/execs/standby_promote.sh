#!/usr/bin/env bash
set -e
source $EVENTS_SCRIPTS_FOLDER/includes/anotate_event_processing.sh
source $EVENTS_SCRIPTS_FOLDER/includes/lock_master.sh
source $EVENTS_SCRIPTS_FOLDER/includes/unlock_standby.sh
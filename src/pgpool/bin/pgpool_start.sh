#!/usr/bin/env bash
set -e

pgpool -n -f $CONFIG_FILE -F $PCP_FILE -a $HBA_FILE
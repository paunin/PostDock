#!/usr/bin/env bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR"/setup_context.sh"

CONFIG_CONTEXT="dev"

echo "> Creating services..."

kubectl create ns $NAMESPACE
kubectl create -f k8s/database-service/*
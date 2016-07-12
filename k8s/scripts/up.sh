#!/usr/bin/env bash

NAMESPACE="app"
CLUSTER_HOST="http://127.0.0.1:8080"


CONFIG_CONTEXT="dev"

echo "> Creating services..."

kubectl create --server=$CLUSTER_HOST ns $NAMESPACE
kubectl create --server=$CLUSTER_HOST --namespace=$NAMESPACE -f k8s/database-service/
#!/usr/bin/env bash

NAMESPACE="app"
CLUSTER_HOST="http://localhost:8080"

kubectl config set-cluster app-cluster --server=$CLUSTER_HOST
kubectl config set-context app --namespace=$NAMESPACE --cluster=app-cluster
kubectl config use-context app
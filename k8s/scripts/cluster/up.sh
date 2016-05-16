#!/usr/bin/env bash

set -e

export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)

docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --pid=host \
    --privileged=true \
    --name=kubelet \
    -d \
    gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION} \
    /hyperkube kubelet \
        --containerized \
        --hostname-override="127.0.0.1" \
        --address="0.0.0.0" \
        --api-servers=http://localhost:8080 \
        --config=/etc/kubernetes/manifests \
        --cluster-dns=10.0.0.10 \
        --cluster-domain=cluster.local \
        --allow-privileged=true --v=2


kubectl config set-cluster app-cluster --server=http://localhost:8080
kubectl config set-context app-cluster --cluster=app-cluster
kubectl config use-context app-cluster

export DNS_REPLICAS=1
export DNS_DOMAIN=cluster.local
export DNS_SERVER_IP=10.0.0.10

wget http://kubernetes.io/docs/getting-started-guides/docker-multinode/skydns.yaml.in -O build/skydns.yaml.in
sed -e "s/{{ pillar\['dns_replicas'\] }}/${DNS_REPLICAS}/g;s/{{ pillar\['dns_domain'\] }}/${DNS_DOMAIN}/g;s/{{ pillar\['dns_server'\] }}/${DNS_SERVER_IP}/g" build/skydns.yaml.in > ./build/skydns.yaml

docker-machine ssh `docker-machine active` -N -L 8080:localhost:8080 &

echo 'Waiting for the cluster...' && sleep 90
kubectl create namespace kube-system
kubectl create -f ./build/skydns.yaml

kubectl create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml
# Example for k8s
## Pre-requirements

* kubernetes cluster up and running
* local `kubectl` tool

## How to install the example

* Create namespace by `kubectl create -f ./namespace/`
* Create configs: `kubectl create -f ./configs/`
* Create volumes `kubectl create -f ./volumes/`
* Create services `kubectl create -f ./services/`
* Create nodes `kubectl create -f ./nodes/`
* Create pgpool `kubectl create -f ./pgpool/`
* See containers are running `kubectl get pod --namespace=mysystem` (give it some time to warm up the cluster after all containers are running)
* Test by commands and see status of the cluster

```
# cluster status on nodes
kubectl get pod | grep db-node  | awk '{print $1}' | while read pod ; do echo "$pod": ; kubectl  exec $pod -- bash -c 'gosu postgres repmgr cluster show' ; done

# cluster status on pgpool
kubectl get pod | grep pgpool | awk '{print $1 }' | while read pod; do echo "$pod": ;kubectl exec $pod -- bash -c 'PGCONNECT_TIMEOUT=$CHECK_PGCONNECT_TIMEOUT  PGPASSWORD=$CHECK_PASSWORD psql -U $CHECK_USER -h 127.0.0.1 template1 -c "show pool_nodes"' ; done
```

## Persistence in the cluster (AWS example)

* **Example1:** Modify volume objects in the files `./volumes/volume-*.yml` and un-comment section about EBS
* **Example2:** Instead of having `emptyDir` in configurations for nodes in files `nodes/*.yml` you should un-comment lines in the end of the files

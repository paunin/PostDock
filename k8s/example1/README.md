# Example for k8s
## Pre-requirements

* kubernetes cluster up and running
* local `kubectl` tool

## How to install the example

* Create namespace by `kubectl create -f ./namespace/`
* Create configs: `kubectl create -f ./configs/`
* Create services `kubectl create -f ./services/`
* Create tnodes `kubectl create -f ./nodes/`
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

Instead of having `emptyDir` in configurations for nodes in files `nodes/*.yml` you should uncomment lines in the end of the files
and also setup claims and volumes by command `kubectl create -f ./volumes/` right after creation of namespace

## Version  k8s <1.5
For k8s <1.5 you might want to use `petset` objects instead of `StatefulSet` - so simply replace block:
```
apiVersion: apps/v1beta1
kind: StatefulSet
```
by block:
```
apiVersion: apps/v1alpha1
kind: PetSet
```
in all files `nodes/*.yml`


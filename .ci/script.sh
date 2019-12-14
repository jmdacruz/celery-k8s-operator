#!/bin/bash

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

function check(){
    if [ "$1" -ne "0" ]; then
        if [ ! -z "$2" ]; then
            >&2 echo "Error: $2"
        fi
        exit 1
    fi
}

function wait_for_object_creation(){
    retry=0
    retry_limit=10
    if [ ! -z "$3" ]; then
        retry_limit=$3
    fi
    sleep_time=1
    if [ ! -z "$4" ]; then
        sleep_time=$4
    fi
    [ -n "$1" ] && [ -n "$2" ] && while [ $(kubectl get $1 -n $2 >/dev/null 2>&1; echo $?) -ne 0 ] && [ "$retry" -lt "$retry_limit" ]; do
        retry=$((retry+1))
        sleep $sleep_time
    done

    if [ "$retry" -eq "$retry_limit" ]; then
        >&2 echo "Timeout waiting for Kubernetes object $1 on namespace $2"
        (exit 1)
    else
        (exit 0)
    fi

}


docker build -t celery-operator:latest ..
check $?
docker build -t add-operator-example:latest ../examples
check $?

kind load docker-image celery-operator:latest
check $?
kind load docker-image add-operator-example:latest
check $?

kubectl apply -f ../deploy/crd.yml
check $?
kubectl apply -f ../deploy/namespace.yml
check $?
kubectl apply -f ../deploy/rbac.yml
check $?
kubectl apply -f ../deploy/operator.yml
check $?

kubectl apply -f ../examples/celery.application.redis.yaml
check $?

# Wait for workers to be available
wait_for_object_creation deployment/add-operator-example-worker celery-example
check $?
kubectl wait --for=condition=available --timeout=60s deployment/add-operator-example-worker -n celery-example
check $?
# Wait for flower to be available
wait_for_object_creation deployment/add-operator-example-flower celery-example
check $?
kubectl wait --for=condition=available --timeout=60s deployment/add-operator-example-flower -n celery-example
check $?

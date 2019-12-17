#!/bin/bash

source ./tools.sh

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

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

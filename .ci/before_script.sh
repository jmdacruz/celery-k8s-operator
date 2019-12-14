#!/bin/bash


function check(){
    if [ "$1" -ne "0" ]; then
        if [ ! -z "$2" ]; then
            >&2 echo "Error: $2"
        fi
        exit 1
    fi
}


DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

echo "Creating Kubernetes cluster using kind"
kind delete cluster -q
check $? "Deleting kind cluster"
kind create cluster -q --config kind.yml
check $? "Creating kind cluster"

echo "Starting kubectl proxy"
kubectl proxy &
proxy_pid=$!
if kill -0 "$proxy_pid"; then
    echo "kubectl proxy is running"
else
    >&2 echo "Could not start kubectl proxy"
    exit 1
fi

popd
#!/bin/bash

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

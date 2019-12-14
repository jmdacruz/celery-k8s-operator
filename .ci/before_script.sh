#!/bin/bash


function check(){
    if [ "$?" -ne "0" ]; then
        exit 1
    fi
}


DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME


kind delete cluster -q
check $?
kind create cluster -q --config kind.yml
check $?

popd
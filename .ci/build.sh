#!/bin/bash

source ./tools.sh

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

docker build -t celery-operator:latest ..
check $?
docker build -t add-operator-example:latest ../examples
check $?

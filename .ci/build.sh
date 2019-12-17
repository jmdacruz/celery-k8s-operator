#!/bin/bash

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

source ./tools.sh

docker build -t celery-operator:latest ..
check $?
docker build -t add-operator-example:latest ../examples
check $?

popd

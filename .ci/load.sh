#!/bin/bash

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

source ./tools.sh

kind load docker-image celery-operator:latest
check $?
kind load docker-image add-operator-example:latest
check $?

popd
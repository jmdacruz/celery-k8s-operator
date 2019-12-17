#!/bin/bash

source ./tools.sh

DIRNAME="$( cd "$(dirname "$0")" ; pwd -P )"
pushd $DIRNAME

kind load docker-image celery-operator:latest
check $?
kind load docker-image add-operator-example:latest
check $?

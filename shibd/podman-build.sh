#!/bin/bash

if [ $# -eq 0 ]
then
    echo "I need a tag."
    exit 1
fi

podman build --no-cache -t quay.io/tike/openshift-sp-shibd:$1 .

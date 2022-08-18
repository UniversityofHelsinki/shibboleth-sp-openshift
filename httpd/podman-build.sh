#!/bin/bash

if [ $# -eq 0 ]
then
    echo "I need a tag."
    exit 1
fi

podman build -t quay.io/tike/openshift-sp-httpd:$1 .

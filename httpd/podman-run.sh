#!/bin/bash

if [ $# -eq 0 ]
then
    echo "I need a tag."
    exit 1
fi

source ./podman-vars.sh

set +x
podman rm -f $CONTAINERNAME
podman run -d -p 8080:8080 --name $CONTAINERNAME $IMAGEREPO:$1

#!/bin/bash 

if [ $# -eq 0 ]
then
    echo "I need a tag."
    exit 1
fi

source podman-vars.sh

podman rm -f $CONTAINERNAME
podman run -d \
    -p 8080:8080 \
    --group-add 0 \
    --name $CONTAINERNAME \
    --systemd false \
    $IMAGEREPO:$1

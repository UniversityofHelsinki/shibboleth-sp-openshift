#!/bin/bash

if [ $# -eq 0 ]
then
    echo "I need a tag."
    exit 1
fi

source podman-vars.sh

podman build --no-cache -f Dockerfile -t $IMAGEREPO:$1 .

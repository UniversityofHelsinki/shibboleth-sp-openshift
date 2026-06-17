#!/bin/bash

source ./podman-vars.sh

podman tag $IMAGEREPO:next $IMAGEREPO:prod-test
podman push $IMAGEREPO:next 
podman push $IMAGEREPO:prod-test

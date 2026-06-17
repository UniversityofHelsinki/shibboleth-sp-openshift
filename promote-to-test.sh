#!/bin/bash

# Expects you to be logged in into quay.io and have skopeo installed.

function promote () {
	NAMEBASE=quay.io/tike/openshift-sp
	echo "promoting $NAMEBASE-$1:next to :test and :latest"
	skopeo copy "docker://$NAMEBASE-$1:next" "docker://$NAMEBASE-$1:test"
	skopeo copy "docker://$NAMEBASE-$1:next" "docker://$NAMEBASE-$1:latest"
}

if [[ " $1 " == " httpd " ]]; then
	promote httpd
elif [[ " $1 " == " shibd " ]]; then
	promote shibd
else
	promote httpd
	promote shibd
fi


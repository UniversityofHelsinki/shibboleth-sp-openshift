#!/bin/bash
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function build-next () {
	# echo "building $DIR/$1"
	cd "$DIR/$1"
	./podman-build.sh next
	cd -
}

function push-next () {
	# echo "pushing $DIR/$1"
	cd "$DIR/$1"
	./podman-pushnext.sh
	cd -
}

if [[ " $1 " == " httpd " ]]; then
	build-next httpd
	push-next httpd
elif [[ " $1 " == " shibd " ]]; then
	build-next shibd
	push-next shibd
else
	build-next shibd
	build-next httpd
	push-next shibd
	push-next httpd
fi


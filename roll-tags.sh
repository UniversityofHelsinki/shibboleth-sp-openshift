#!/bin/bash

# Expects you to be logged in into quay.io and have skopeo installed.

if [ -z $1 ]
then
    echo "Usage: $0 registry/organization/image (NO TAG!)"
    echo "For reference:"
    echo " - quay.io/tike/openshift-sp-shibd"
    echo " - quay.io/tike/openshift-sp-httpd"
    exit 1
fi

function roll_tags () {
    skopeo copy "docker://$1:prev-2" "docker://$1:prev-3"
    skopeo copy "docker://$1:prev" "docker://$1:prev-2"
    skopeo copy "docker://$1:prod" "docker://$1:prev"
    skopeo copy "docker://$1:test" "docker://$1:prod"
}

TEST_DIGEST=$(skopeo inspect docker://$1:test 2>/dev/null | jq -r  '.Digest')
PROD_DIGEST=$(skopeo inspect docker://$1:prod 2>/dev/null | jq -r  '.Digest')

if [[ "$PROD_DIGEST" != "$TEST_DIGEST" ]]
then
    # echo "run"
    echo ":prod = $PROD_DIGEST"
    echo ":test = $TEST_DIGEST"
    roll_tags "$1"
else
    echo ":prod = $PROD_DIGEST"
    echo ":test = $TEST_DIGEST"
    echo "prod and test tag digests match, do not run"
fi

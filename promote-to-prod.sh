#!/bin/bash

# Expects you to be logged in into quay.io and have skopeo installed.

function datetag_current_prod () {
	DATE=$(date -I)
	TAGINDEX=$(skopeo list-tags docker://$1 | jq --arg datetag "$DATE"  '.Tags | index($datetag)')
	if [[ " $TAGINDEX " == " null " ]]; then
		skopeo copy "docker://$1:prod" "docker://$1:$DATE"
	fi
}

function roll_tags () {
    echo "Gonna roll tags for $1"
    datetag_current_prod $1
    skopeo copy "docker://$1:prev-2" "docker://$1:prev-3"
    skopeo copy "docker://$1:prev" "docker://$1:prev-2"
    skopeo copy "docker://$1:prod" "docker://$1:prev"
    skopeo copy "docker://$1:test" "docker://$1:prod"
    skopeo copy "docker://$1:test" "docker://$1:master"
}

function roll_tags_for () {
	NAMEBASE=quay.io/tike/openshift-sp	
	IMAGEREPO=$NAMEBASE-$1

	TEST_DIGEST=$(skopeo inspect docker://$IMAGEREPO:test 2>/dev/null | jq -r  '.Digest')
	PROD_DIGEST=$(skopeo inspect docker://$IMAGEREPO:prod 2>/dev/null | jq -r  '.Digest')

	if [[ "$PROD_DIGEST" != "$TEST_DIGEST" ]]
	then
    		# echo "run"
    		echo "$IMAGEREPO:prod = $PROD_DIGEST"
    		echo "$IMAGEREPO:test = $TEST_DIGEST"
    	roll_tags "$IMAGEREPO"
	else
    		echo "$IMAGEREPO:prod = $PROD_DIGEST"
    		echo "$IMAGEREPO:test = $TEST_DIGEST"
    		echo "prod and test tag digests match, will not run. Maybe run promote-to-test.sh first?"
	fi
}

if [[ " $1 " == " httpd " ]]; then
	# echo "rolling httpd"
	roll_tags_for httpd
elif [[ " $1 " == " shibd " ]]; then
	# echo "rolling shibd"
	roll_tags_for shibd
else
	# echo "rolling both"
	roll_tags_for httpd
	roll_tags_for shibd
fi


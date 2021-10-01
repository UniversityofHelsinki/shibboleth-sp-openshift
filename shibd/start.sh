#!/bin/sh

# Symbolically link any files in /shib-config/ (mounted from ConfigMaps) into
# /etc/shibboleth/, overwriting any matching default files.
ln -sf -t /etc/shibboleth/ /shib-config/*
# Open shibd.log and start printing it to stdout
tail -F -c +0 /var/log/shibboleth/shibd.log 2> /dev/null &
# Start shibd
/usr/sbin/shibd -F
# Sleep for a bit after shibd dies so that tail has time to print all of the log
sleep 15

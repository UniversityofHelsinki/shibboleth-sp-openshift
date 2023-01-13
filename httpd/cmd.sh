#!/bin/bash

ln -sf -t /etc/shibboleth/ /shib-config/*
httpd -D FOREGROUND

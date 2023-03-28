#!/bin/bash
#
# This script establishes the first run 'trust' of the ssh connection
#

# safety checks
if [ ! -f /config/private.key ]; then
    echo "Missing private.key - need remote host private key"
    exit
fi
if [ ! -f /config/settings.sh ]; then
    echo "Missing settings.sh - please configure prior to running"
    exit
fi

# Load settings - ACCOUNT, SSHOPT, BWLIMIT, TIMEOUT
source ./config/settings.sh

# copy the current known hosts into the right location
cp /config/known_hosts /root/.ssh/known_hosts

# initiate a ssh connection - this should require user interactivity
ssh $SSHOPT -i /config/private.key $ACCOUNT ls

# copy the updated (hopefully) known_hosts file to config
cp /root/.ssh/known_hosts /config/known_hosts

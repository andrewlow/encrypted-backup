#!/bin/bash
#
# This script establishes the first run 'trust' of the ssh connection
#

# safety checks
if [ ! -f /config/private.key ]; then
    echo "Missing private.key - need remote host private key"
    exit
fi
if [ ! -f /config/account.txt ]; then
    echo "Missing remote host information - create one before running container"
    exit
fi
# load remote host
ACCOUNT=$(cat /config/account.txt)

# load ssh extra flags
SSHOPT=$(cat /config/sshextra.txt)

# copy the current known hosts into the right location
cp /config/known_hosts /root/.ssh/known_hosts

# initiate a ssh connection - this should require user interactivity
ssh $SSHOPT -i /config/private.key $ACCOUNT ls

# copy the updated (hopefully) known_hosts file to config
cp /root/.ssh/known_hosts /config/known_hosts

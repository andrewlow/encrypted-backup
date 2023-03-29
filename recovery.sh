#!/bin/bash
#
# This script remotely mounts the encrypted filesystem (read only) and provides a plaintext view
# It is expected to be run interactively, so the user can go in and recover files
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
cp -a /config/known_hosts /root/.ssh/known_hosts

# use sshfs to mount the remote encrypted files locally
sshfs $SSHOPT -oIdentityFile=/config/private.key $ACCOUNT:./external/encrypted /encrypted

# Setup encrypted mount as plaintext
gocryptfs -nosyslog -config /config/gocryptfs.conf -passfile /config/passwd.txt -ro /encrypted /mnt

# 
echo 'useful doc..'

# run a shell for the user to work with
/bin/bash


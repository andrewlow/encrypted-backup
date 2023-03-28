#!/bin/bash
#
# This script remotely mounts the encrypted filesystem (read only) and provides a plaintext view
# It then uses tree to determine if the same filenames are present on both systems
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

# Use rsync to do file attribute comparison (not used, but provided as an example)
#rsync --dry-run -ai --delete /originals/ /mnt/

tree /originals > /tmp/originals.txt
tree /mnt > /tmp/remote.txt
diff /tmp/originals.txt /tmp/remote.txt

# Undo gocryptfs
umount /mnt
# Give it a second to complete
sleep 1
# Undo sshfs
umount /encrypted

# copy the updated (hopefully) known_hosts file to config
cp -a /root/.ssh/known_hosts /config/known_hosts

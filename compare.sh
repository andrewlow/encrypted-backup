#!/bin/bash
#
# This script remotely mounts the encrypted filesystem (read only) and provides a plaintext view
# It then uses rsync to do a --dry-run comparison between the original and the remote
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

# use sshfs to mount the remote encrypted files locally
sshfs $SSHOPT -oIdentityFile=/config/private.key $ACCOUNT:./external/encrypted /encrypted

# Setup encrypted mount as plaintext
gocryptfs -nosyslog -config /config/gocryptfs.conf -passfile /config/passwd.txt -ro /encrypted /mnt

# Use rsync to do file attribute comparison 
rsync --dry-run -ai --delete /originals /mnt

# Undo gocryptfs
umount /mnt
# Give it a second to complete
sleep 1
# Undo sshfs
umount /encrypted

# copy the updated (hopefully) known_hosts file to config
cp /root/.ssh/known_hosts /config/known_hosts

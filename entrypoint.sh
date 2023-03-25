#!/bin/bash
#set -e

echo `date` "encrypted-backup starting.."

# safety checks
if [ ! -f /config/gocryptfs.conf ]; then
    echo "Missing gocryptfs.conf - need to initialize before running container"
    exit
fi
if [ ! -f /config/private.key ]; then
    echo "Missing private.key - need remote host private key"
    exit
fi
if [ ! -f /config/passwd.txt ]; then
    echo "Missing password file - create one before running container"
    exit
fi
if [ ! -f /config/account.txt ]; then
    echo "Missing remote host information - create one before running container"
    exit
fi
if [ ! -f /config/known_hosts ]; then
    echo "Missing known_hosts, run 'make ssh' to fix"
    exit        
fi 
# load remote host
ACCOUNT=$(cat /config/account.txt)

# load ssh extra flags
SSHOPT=$(cat /config/sshextra.txt)

# Setup encrypted reverse mount
gocryptfs -allow_other -nosyslog -reverse -config /config/gocryptfs.conf -passfile /config/passwd.txt -fg /originals /encrypted &

# Give gocryptfs time to start up
sleep 4

# copy in the known_hosts file
cp -a /config/known_hosts /root/.ssh/known_hosts

# Pre backup check - is the external drive mounted?
if ! ssh $SSHOPT -i /config/private.key $ACCOUNT test -e ./external/MOUNTED; then 
    echo "Remote external drive is not detected"
    exit
fi

# 
# timeout 14400 seconds = 4hrs
#
timeout 14400 rsync -avz --bwlimit=3000 --delete --delete-excluded -e "ssh $SSHOPT -i /config/private.key" /encrypted $ACCOUNT:./external

# Umount the crypted fs
umount /encrypted

# Update the known_hosts file (may not be needed?)
cp -a /root/.ssh/known_hosts /config/known_hosts

echo "sleep before exit"
sleep 2

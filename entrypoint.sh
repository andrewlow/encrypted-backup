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
if [ ! -f /config/known_hosts ]; then
    echo "Missing known_hosts, run 'make ssh' to fix"
    exit        
fi 
if [ ! -f /config/settings.sh ]; then
    echo "Missing settings.sh - please configure prior to running"
    exit
fi

# Load settings - ACCOUNT, SSHOPT, BWLIMIT, TIMEOUT
source ./config/settings.sh

# Setup encrypted reverse mount
gocryptfs -nosyslog -reverse -config /config/gocryptfs.conf -passfile /config/passwd.txt /originals /encrypted

# copy in the known_hosts file
cp -a /config/known_hosts /root/.ssh/known_hosts

# Pre backup check - is the external drive mounted?
if ! ssh $SSHOPT -i /config/private.key $ACCOUNT test -e ./external/MOUNTED; then 
    echo "Remote external drive is not detected"
    exit
fi
#
# Check how many files are going to be deleted
#
DELETED=$(rsync -avz --dry-run --delete --delete-excluded --stats -e "ssh $SSHOPT -i /config/private.key" /encrypted $ACCOUNT:./external | fgrep 'Number of deleted files' | cut -d' ' -f5 | tr -d ,)

#
# Only perform actual rsync if the deleted number is low enough, and it is not forced
#
if(($DELETED > $RMLIMIT)) && [[ ! -f /config/force ]]; then
   echo -e "\n\nDetected "$DELETED" deletions, exceeds limit of "$RMLIMIT" deleted files, aborting."
   echo -e "Create ./config/force to force backup to proceed\n\n"
else
# 
# Announce and clear force if present
#
if [[ -f /config/force ]]; then
  echo "Backup forced, removing ./config/force"
  rm /config/force
fi
#
# Peform rsync
#
timeout $TIMEOUT rsync -avz --bwlimit=$BWLIMIT --delete --delete-excluded --stats -e "ssh $SSHOPT -i /config/private.key" /encrypted $ACCOUNT:./external
fi

# Umount the crypted fs
umount /encrypted

# Update the known_hosts file (may not be needed?)
cp -a /root/.ssh/known_hosts /config/known_hosts


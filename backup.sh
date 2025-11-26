#!/bin/bash
#set -e

# Uses slack protocol, but also works with mattermost
post_slack_webhook () {
    if [ -v WEBHOOK_URL ]; then
	COLOR="#Ca0000"
	if [ "$2" = "SUCCESS" ]; then
	    COLOR="#00ca00"
	fi
        curl -i -X POST -H 'Content-Type: application/json' -d "{\"attachments\": [{\"author_name\": \"Encrypted Backup\", \"Color\": \"$COLOR\", \"text\": \"$1\"}]}" $WEBHOOK_URL
    fi
}

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

# Load settings - ACCOUNT, SSHOPT, BWLIMIT, TIMEOUT, WEBHOOK_URL
source ./config/settings.sh

# Setup encrypted reverse mount
gocryptfs -nosyslog -reverse -config /config/gocryptfs.conf -passfile /config/passwd.txt /originals /encrypted

# Pre backup check - is the external host reachable?
if ! ssh $SSHOPT -i /config/private.key $ACCOUNT /bin/true; then
    echo "Remote host is not reachable"
    post_slack_webhook "Encrypted backup failed\n\nRemote host is not reachable." "FAILURE"
    exit
fi

# Pre backup check - is the external drive mounted?
if ! ssh $SSHOPT -i /config/private.key $ACCOUNT test -e ./external/MOUNTED; then 
    echo "Remote external drive is not detected"
    post_slack_webhook "Encrypted backup failed\n\nRemote external drive not detected." "FAILURE"
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
   post_slack_webhook "Encrypted backup failed\n\nDetected "$DELETED" deletions, which exceeds the limit of "$RMLIMIT"." "FAILURE"
   exit
else
# 
# Announce and clear force if present
#
if [[ -f /config/force ]]; then
  echo "Backup forced, removing ./config/force"
  rm /config/force
fi
# 
# Check if DRYRUN is set, if so specify --dry-run rsync option
#
if ! [ -z "$DRYRUN" ]; then
	RSYNC_OPT="--dry-run"
fi
#
# Peform rsync
#
{
timeout $TIMEOUT rsync -az --bwlimit=$BWLIMIT $RSYNC_OPT --delete --delete-excluded --info=flist0,stats2 -e "ssh $SSHOPT -i /config/private.key" /encrypted $ACCOUNT:./external
} > /tmp/rsync.log
cat /tmp/rsync.log
post_slack_webhook "`cat /tmp/rsync.log`" "SUCCESS"
rm /tmp/rsync.log
fi

# Umount the crypted fs
umount /encrypted

# Dump free disk space on target
ssh $SSHOPT -i /config/private.key $ACCOUNT df ./external



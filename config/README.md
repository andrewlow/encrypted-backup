# Files

- passwd.txt - a very long password for gocrypt
- private.key - ssh key for account.txt
- settings.sh - variables for
   - ACCOUNT - user@remote.org
   - SSHOPT - optional, ssh option string
   - BWLIMIT - numeric value, passed to rsync `--bwlimit=NNN`
   - TIMEOUT - number of seconds to run before being interrupted
   - RMLIMIT - abort if number of deletions exceeds this value
   - NOLIMIT - if defined, ignore RMLIMIT and always proceed
   - WEBHOOK_URL - optional, slack/mattermost URL for posting status
   - DRYRUN - do not actually back up - just fake it

To ignore the deletion limit for one run, create the file `force` in this directory to bypass the RMLIMIT

Generated
- gocryptfs.conf - make init
- known_hosts - make ssh


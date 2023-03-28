# Files

- passwd.txt - a very long password for gocrypt
- private.key - ssh key for account.txt
- settings.sh - variables for
   - ACCOUNT - user@remote.org
   - SSHOPT - optional, ssh option string
   - BWLIMIT - numeric value, passed to rsync `--bwlimit=NNN`
   - TIMEOUT - number of seconds to run before being interrupted

Generated
- gocryptfs.conf - make init
- known_hosts - make ssh


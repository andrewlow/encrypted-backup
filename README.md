# encrypted-backup
Companion to restricted-shell. Performs rsync of encrypted files to remote location.

## Philosphy

The container should "contain" the code. Output should be to stdout.

This is a periodic job, cron on the host should launch it from time to time.

The container should exit with a non-zero exit code if there was a problem

https://stackoverflow.com/questions/60625863/get-exit-code-from-docker-entrypoint-command


## Setup

Create ./config/passwd.txt according to the gocryptfs password file rules

Run `make init` to initialize the encrypted view of the data

Run `make ssh` to create the known_hosts file, this is interactive

Create ./config/account.txt, it should contain user@remote.org 

Optional, create ./config/sshextras.txt to have additional ssh command line flags (like '-p 8022')

Setup a cron job to run the container on a regular cadence (once a day)


## Assumptions

There is a remote server running the companion restricted shell

That restricted shell exposes a volume (probably a USB drive) that is mounted in ~/external

There is a file on the root of that external drive `MOUNTED` thus the file appears as `~/external/MOUNTED` this is used to validate that the remote filesystem is present and ready for data to flow



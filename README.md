# encrypted-backup
Companion to [restricted-shell](https://github.com/andrewlow/restricted-shell). Performs rsync of encrypted files to remote location.

All encryption and secrets stay on the sending system. The remote system only ever gets the encrypted data.

## Philosphy

The container should "contain" the code, secrets are external to the container. Output should be to stdout.

This is a long running container. A cron varient (superchronic) is used to run backups.

## Setup

Create `./config/passwd.txt` according to the gocryptfs password file rules

Run `make init` to initialize the encrypted view of the data

Create the `./config/settings.sh` file based on the template `./config/settings.sh.template`. 

Run `make ssh` to create the `./config/known_hosts` file, this is interactive and you'll need to answer "yes" to storing the known host.

Create a `./config.mk` based on `./config.mk.template`. This file is one or more Docker `-v` volume mount commands, mapping the host filesystem into the container `/orginals/` file tree. These are the files that will be backed up remotely.

Setup a cron job to run the container on a regular cadence (once a day)


## Assumptions

There is a remote server running the companion [restricted-shell](https://github.com/andrewlow/restricted-shell)

That restricted shell exposes a volume (probably a USB drive) that is mounted in ~/external

There is a file on the root of that external drive `MOUNTED` thus the file appears as `~/external/MOUNTED` this is used to validate that the remote filesystem is present and ready for data to flow


## Disaster Recovery

The two critical files to back up somewhere safe are

- `./config/gocryptfs.conf`
- `./config/passwd.txt`

You can additionally capture the masterkey by running `make dumpmasterkey` which can be used to recover.

## Utilities

`make compare` - performs a comparison between the files mapped into `/originals` and the remote system. This comparison is done at the filename level only. The remote system is mounted read only, so this is safe to run in most cases and will give you data about what still needs to be backed up if you have new files on the host system.

`make recover` - similar to the comparison above, but drops you into an interactive shell with the remote files mounted locally and then decrypted (locally).  This serves as an example of how you would recover from a disaster and get your files back from the encrypted destination.

## Links

[gocryptfs](https://nuetzlich.net/gocryptfs/) - file-based encryption that is implemented as a mountable FUSE filesystem

[rsync](https://rsync.samba.org/) - old school file sync utility, it works

[openssh](https://www.openssh.com/) - secure shell, used as network transport

[sshfs](https://en.wikipedia.org/wiki/SSHFS) - FUSE filesystem over ssh

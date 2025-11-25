#
#
NAME = encrypted-backup
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# This is used for local build
build:
	- docker rm $(NAME)
	docker pull ubuntu
	docker pull alpine
	docker build --tag $(NAME) .

#
# Initialize gocryptfs - run only once - assumes container is running
#
init:
	docker exec -it $(NAME) \
		gocryptfs -allow_other --init -nosyslog -reverse -config /config/gocryptfs.conf -passfile /config/passwd.txt /encrypted 

#
# Use mount the remote dir decrypted, and compare filenames
#
compare:
	docker exec -it $(NAME) \
		/compare.sh

#
# Interactive recovery mode
#
recover:
	docker exec -it $(NAME) \
                /recover.sh

#
# initialize or update known_hosts
#
ssh:
	docker exec -it $(NAME) \
		/ssh-setup.sh

#
# The master key is important for recovery in case of disaster
#
dumpmasterkey:
	docker exec -it $(NAME) \
		bash -c 'cat /config/passwd.txt | gocryptfs-xray -dumpmasterkey /config/gocryptfs.conf'

#
# Force a backup run (normally triggered by crontab)
#
backup:
	docker exec -it $(NAME) \
		/backup.sh


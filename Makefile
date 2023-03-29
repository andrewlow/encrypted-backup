#
#
NAME = encrypted-backup
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# get file mapping paths to host
include config.mk

build:
	- docker rm $(NAME)
	docker pull ubuntu
	docker pull alpine
	docker build --tag $(NAME) .
	docker create \
		--name=$(NAME) \
		-e TZ=America/Toronto \
		--privileged \
		--cap-add SYS_ADMIN \
		--device /dev/fuse \
		-v $(ROOT_DIR)/config:/config \
		$(PATH_MAP) \
		$(NAME)

#
# Initialize gocryptfs - run only once
#
init:
	docker run \
		--rm \
                -e TZ=America/Toronto \
                --privileged \
                --cap-add SYS_ADMIN \
                --device /dev/fuse \
		-u $(shell id -u ${USER}):$(shell id -g ${USER}) \
                -v $(ROOT_DIR)/config:/config \
		$(NAME) \
		gocryptfs -allow_other --init -nosyslog -reverse -config /config/gocryptfs.conf -passfile /config/passwd.txt /encrypted 

#
# Use mount the remote dir decrypted, and compare filenames
#
compare:
	docker run \
		--rm \
		-e TZ=America/Toronto \
		--privileged \
		--cap-add SYS_ADMIN \
		--device /dev/fuse \
		-v $(ROOT_DIR)/config:/config \
		$(PATH_MAP) \
		$(NAME) \
		/compare.sh

#
# Interactive recovery mode
#
recover:
	docker run \
                --rm \
		-it \
                -e TZ=America/Toronto \
                --privileged \
                --cap-add SYS_ADMIN \
                --device /dev/fuse \
                -v $(ROOT_DIR)/config:/config \
                $(PATH_MAP) \
                $(NAME) \
                /recover.sh

#
# initialize or update known_hosts
#
ssh:
	docker run \
		-it \
		--rm \
                -v $(ROOT_DIR)/config:/config \
                $(NAME) \
		/ssh-setup.sh

#
# The master key is important for recovery in case of disaster
#
dumpmasterkey:
	docker run \
                --rm \
                -e TZ=America/Toronto \
                --privileged \
                --cap-add SYS_ADMIN \
                --device /dev/fuse \
                -u $(shell id -u ${USER}):$(shell id -g ${USER}) \
                -v $(ROOT_DIR)/config:/config \
                $(NAME) \
		bash -c 'cat /config/passwd.txt | gocryptfs-xray -dumpmasterkey /config/gocryptfs.conf'

#
# Perform a backup cycle
#
backup:
	docker start --attach $(NAME)


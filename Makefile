#
#
NAME = encrypted-backup
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker build --tag $(NAME) .
	docker create \
		--name=$(NAME) \
		-e TZ=America/Toronto \
		--privileged \
		--cap-add SYS_ADMIN \
		--device /dev/fuse \
		-v $(ROOT_DIR)/config:/config \
		-v /home/myuser/Music:/originals/Music \
		$(NAME)

#
# Initialize gocryptfs - run once
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
# initialize known_hosts
#
ssh:
	docker run \
		-it \
		--rm \
                -v $(ROOT_DIR)/config:/config \
                $(NAME) \
		/ssh-setup.sh

#
# The master key is important for recovery in case of disaster?
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

start:
	docker start --attach $(NAME)

# Update the container
update:
	- docker rm $(NAME)-old
	docker rename $(NAME) $(NAME)-old
	make build
	docker stop $(NAME)-old
	make start

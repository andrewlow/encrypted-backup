#
#
NAME = encrypted-backup
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker build --tag $(NAME) .
	docker create \
		--name=$(NAME) \
		-v $(ROOT_DIR)/config:/config \
		$(NAME)

start:
	docker start $(NAME)

# Update the container
update:
	- docker rm $(NAME)-old
	docker rename $(NAME) $(NAME)-old
	make build
	docker stop $(NAME)-old
	make start

# 
# Builder image - we grab a specific version from the source
#
FROM ubuntu AS builder

# Specify gocrypt version
ENV GOCRYPTFS_VERSION=v2.3.1

RUN apt-get update && \
    apt install -y wget

# We grab the specified version pre-built binary
RUN cd /tmp && \
    wget https://github.com/rfjakob/gocryptfs/releases/download/${GOCRYPTFS_VERSION}/gocryptfs_${GOCRYPTFS_VERSION}_linux-static_amd64.tar.gz -O /tmp/binary.tar.gz && \
    tar xzf /tmp/binary.tar.gz

#
# Runtime image - based on alpine
#
FROM alpine:latest

# Setup binaries
COPY --from=builder /tmp/gocryptfs /usr/local/bin/gocryptfs
COPY --from=builder /tmp/gocryptfs-xray /usr/local/bin/gocryptfs-xray
RUN apk add --no-cache tini tzdata fuse bash rsync openssh-client sshfs tree curl
RUN echo user_allow_other >> /etc/fuse.conf

# Seed the known_hosts file - this should really be 
RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    mkdir /config && \
    touch /config/known_hosts && \
    ln -s /config/known_hosts /root/.ssh/known_hosts

# Ensure mountpoints exist
RUN mkdir /originals && mkdir /encrypted

# Copy in scripts
COPY entrypoint.sh entrypoint.sh
COPY ssh-setup.sh ssh-setup.sh
COPY compare.sh compare.sh
COPY recover.sh recover.sh

# Use script to initialize container at start time
# unclear if I need tini to get exceptions correct - test removing it later
CMD ["/sbin/tini", "/entrypoint.sh"]

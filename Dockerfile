# 
# Builder image - we grab a specific version from the source
#
FROM ubuntu AS builder

# Specify gocrypt version
ENV GOCRYPTFS_VERSION=v2.3.1

RUN apt-get update && \
    apt install -y wget curl

# We grab the specified version pre-built binary
RUN cd /tmp && \
    wget https://github.com/rfjakob/gocryptfs/releases/download/${GOCRYPTFS_VERSION}/gocryptfs_${GOCRYPTFS_VERSION}_linux-static_amd64.tar.gz -O /tmp/binary.tar.gz && \
    tar xzf /tmp/binary.tar.gz

# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.39/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=c98bbf82c5f648aaac8708c182cc83046fe48423 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

#
# Runtime image - based on alpine
#
FROM alpine:latest

# Setup binaries
COPY --from=builder /tmp/gocryptfs /usr/local/bin/gocryptfs
COPY --from=builder /tmp/gocryptfs-xray /usr/local/bin/gocryptfs-xray
COPY --from=builder /usr/local/bin/supercronic /usr/local/bin/supercronic
RUN apk add --no-cache tzdata fuse bash rsync openssh-client sshfs tree curl
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
COPY backup.sh /backup.sh
COPY ssh-setup.sh /ssh-setup.sh
COPY compare.sh /compare.sh
COPY recover.sh /recover.sh

# And the crontab

CMD [ "/usr/local/bin/supercronic", "/config/crontab" ]

#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
FROM alpine:3.15

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION

ARG S6VERSION=2.2.0.3

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

RUN \
  echo "**** install build packages ****" \
  && apk add --no-cache --virtual=build-dependencies tar curl jq patch \
  && set -x && ARCH=$(uname -m) \
  && case "${ARCH}" in \
     armv7) \
        ARCH='arm' && \
        curl -o /usr/bin/qemu-${ARCH}-static -L "https://lsio-ci.ams3.digitaloceanspaces.com/qemu-${ARCH}-static" && \
        chmod +x /usr/bin/qemu-${ARCH}-static ; \
     ;; \
     armhf) \
        ARCH='armhf' && \
        curl -o /usr/bin/qemu-${ARCH}-static -L "https://lsio-ci.ams3.digitaloceanspaces.com/qemu-${ARCH}-static" && \
        chmod +x /usr/bin/qemu-${ARCH}-static ; \
     ;; \
     aarch64) \
        ARCH='aarch64' && \
        curl -o /usr/bin/qemu-${ARCH}-static -L "https://lsio-ci.ams3.digitaloceanspaces.com/qemu-${ARCH}-static" && \
        chmod +x /usr/bin/qemu-${ARCH}-static ; \
      ;; \
  esac \
  && \
  apk del --purge build-dependencies && rm -rf /tmp/*

RUN apk add --no-cache --purge -uU curl && \
    S6ARCH=$(uname -m | sed 's/x86_64/amd64/') && \
    echo "Installing s6 version: $S6VERSION for $S6ARCH" && \
    curl -o /tmp/s6-overlay.tar.gz -jkSL https://github.com/just-containers/s6-overlay/releases/download/v${S6VERSION}/s6-overlay-${S6ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /var/cache/apk/* /tmp/*

COPY ./base/docker-alpine/patch/ /tmp/patch

## RUN FINALIMAGE

RUN \
  echo "**** install runtime packages ****" && \
     apk add --no-cache apk-tools patch procps bash wget busybox tar unzip coreutils shadow jq findutils && \
     mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
     patch -u /etc/s6/init/init-stage2 -i /tmp/patch/etc/s6/init/init-stage2.patch && \
  echo "**** create abc user and make our folders ****" && \
     groupmod -g 1000 users && \
     useradd -u 911 -U -d /config -s /bin/false abc && \
     usermod -G users abc && \
     mkdir -p /app /config /defaults /system && \
     rm -rf /var/cache/apk/*

COPY ./base/docker-alpine/root/ /

ENTRYPOINT ["/init"]

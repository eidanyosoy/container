#!/bin/bash
####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THE DOCKER ARE UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
# shellcheck disable=SC2086
# shellcheck disable=SC2006
## add repositories apk parts
cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

echo "**** update packages ****" && \
    apk --quiet --no-cache --no-progress update && \
    apk --quiet --no-cache --no-progress upgrade

echo "**** install build packages ****" && \
    apk add -U --update --no-cache \
       bash \
       ca-certificates \
       shadow \
       musl \
       findutils \
       coreutils \
       py-pip \
       python3-dev \
       libffi-dev \
       openssl-dev \
       gcc \
       libc-dev \
       make \
       docker

   python -m pip install --no-warn-script-location --upgrade pip setuptools && \
   pip install --no-warn-script-location --no-cache-dir cryptography && \
   pip install --no-warn-script-location --no-cache-dir docker-compose==1.29.2

 echo "*** cleanup system ****" && \
    apk del --quiet --clean-protected --no-progress && \
    rm -f /var/cache/apk/*


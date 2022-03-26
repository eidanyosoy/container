#!/usr/bin/with-contenv bash
# shellcheck shell=bash
######################################################
# Copyright (c) 2021, MrDoob                         #
######################################################
# All rights reserved.                               #
# started from Zero                                  #
# Docker owned from MrDoob                           #
# some codeparts are copyed from sagen from 88lex    #
# sagen is under MIT License                         #
# Copyright (c) 2019 88lex                           #
#                                                    #
# CREDITS: The scripts and methods are based on      #
# ideas/code/tools from ncw, max, sk, rxwatcher,     #
# l3uddz, zenjabba, dashlt, mc2squared, storm,       #
# physk , plexguide and all missed once              #
######################################################
# shellcheck disable=SC2086
# shellcheck disable=SC2046

cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

   apk --quiet --no-cache --no-progress update && \
   apk --quiet --no-cache --no-progress upgrade && \
   apk add --quiet --no-cache --no-progress --virtual=build-dependencies \
      aria2 curl findutils coreutils unzip jq bc unzip shadow musl

ARCH="$(command arch)"
if [ "${ARCH}" = "x86_64" ]; then
   export ARCH="amd64"
elif [ "${ARCH}" = "aarch64" ]; then
     export ARCH="arm64"
elif [ "${ARCH}" = "armv7l" ]; then
     export ARCH="armhf"
else
    echo "**** Unsupported Linux architecture ${ARCH} found, exiting... ****" && exit 1
fi

VERSION=$(curl -sX GET "https://api.github.com/repos/rclone/rclone/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' | sed -e 's_^v__')
aria2c -x2 -k1M -d /tmp -o rclone.zip https://github.com/rclone/rclone/releases/download/v${VERSION}/rclone-v${VERSION}-linux-${ARCH}.zip && \
cd /tmp/ && unzip -q /tmp/rclone.zip
mv /tmp/rclone-*-linux-${ARCH}/rclone /usr/local/bin/
apk del --quiet --purge build-dependencies && \
echo "**** cleanup ****" && \
rm -rf /var/cache/apk/* /tmp/*

if [ -f "/system/rclone/.env" ] && [ -f "/system/rclone/.token" ]; then
   bash startup
fi
if [ ! -f "/system/rclone/.env" ] && [ ! -f "/system/rclone/.token" ]; then
   exit
fi

##E#O#F##

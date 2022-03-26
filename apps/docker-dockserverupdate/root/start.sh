#!/usr/bin/bash
# shellcheck shell=bash
#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196
# shellcheck disable=SC2046

function log() {
   echo "[UPDATE] $(date) ${1}" 
}

apk --quiet --no-cache --no-progress update && \
apk --quiet --no-cache --no-progress upgrade && \
apk del --quiet --clean-protected --no-progress && \
rm -rf /var/cache/apk/* /tmp/*

if [ -z `command -v git` ]; then apk --quiet --no-cache --no-progress add git; fi
if [ -z `command -v curl` ]; then apk --quiet --no-cache --no-progress add curl; fi
sleep 1

FOLDER=${FOLDER}

VERSION=$(curl -sX GET "https://api.github.com/repos/dockserver/dockserver/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' | sed -e 's_^v__')

while true; do
  if [[ -d ${FOLDER} ]]; then
      log "Update DockServer to ${VERSION}" && \
      git -C ${FOLDER} stash --quiet && \
      git -C ${FOLDER} pull --quiet && \
      cd ${FOLDER} && git stash clear
      log "Update DockServer ${VERSION} || done"
  fi
  sleep 86400
done
#E-O-F

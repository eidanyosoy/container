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

### FUNCTION START

function log() {

   echo "[INSTALL] DockServer ${1}"

}

function first() {

   cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

   log "**** update system packages ****" && \
   apk --quiet --no-cache --no-progress update && \
   apk --quiet --no-cache --no-progress upgrade && \
   apk --quiet --no-cache --no-progress add shadow 

   addgroup -S abc
   adduser -S abc -G abc

   PGID=${PGID:-1000}
   PUID=${PUID:-1000}

   groupmod -o -g "$PGID" abc
   usermod -o -u "$PUID" abc

   if test -f "/tmp/LOCAL";then
      rm -rf /tmp/LOCAL
   fi
}

function unwanted() {

echo -e ".git
.github
CONTRIBUTING.md
README.md
SECURITY.md
backup.sh
config.json
get_pull_request_title.rb
renovate.json
wgetfile.sh
.all-contributorsrc
.mergify.yml
changelog-ci-config.yaml
.editorconfig
.gitignore
.gitattributes
log4j
wiki
images
github-metrics.svg
LICENSE
.pre-commit-config.yaml
.imgbotconfig" > /tmp/unwanted

   sed '/^\s*#.*$/d' /tmp/unwanted | while IFS=$'\n' read -ra remove; do
       rm -rf ${FOLDER}/${remove[0]} > /dev/null
   done
   unset remove
   rm -rf /tmp/unwanted
}

function build() {

   install=(curl bc findutils coreutils tar jq rsync)
   log "**** install build packages ****" && \
   apk add --quiet --no-cache --no-progress --virtual=build-dependencies ${install[@]}
   unset install

}

function apps() {

   mkdir -p "${FOLDERTMP}/apps/myapps/" && \
   rsync --remove-source-files --prune-empty-dirs -aqhv --include='**.yml' "${FOLDER}/apps/myapps/" "${FOLDERTMP}/apps/myapps/" && \

   download

   mkdir -p "${FOLDER}/apps/myapps/" && \
   rsync --remove-source-files --prune-empty-dirs -aqhv --include='**.yml' "${FOLDERTMP}/apps/myapps/" "${FOLDER}/apps/myapps/" && \
   rm -rf "${FOLDERTMP}"

}

function download() {

   URL="https://api.github.com/repos/dockserver/dockserver/releases/latest"
   APPVERSION="$(curl -u $USER:$TOKEN -sX GET "${URL}" | jq -r '.tag_name')"
   log "**** downloading dockserver version ${APPVERSION} ****" && \
   rm -rf ${FOLDER}/* && mkdir -p ${FOLDER} && \
   curl -fsSL "${GTHUB}/${APPVERSION}.tar.gz" | tar xzf - -C "${FOLDER}" --strip-components=1 && \
   log "**** Update dockserver to version ${APPVERSION} completed ****"

}

function perms() {

   find "${FOLDER}" -exec chmod a=rx,u+w {} \;
   find "${FOLDER}" -exec chown -hR 1000:1000 {} \;

}

function run() {

while true; do

   export TOKEN=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
   export USER=doob187

   export FOLDER=/opt/dockserver
   export FOLDERTMP=/tmp/dockserver
   export URL="https://api.github.com/repos/dockserver/dockserver/releases/latest"
   export GTHUB="https://github.com/dockserver/dockserver/archive/refs/tags"
   export MINFILES=0
   export APPVERSION="$(curl -u $USER:$TOKEN -sX GET "${URL}" | jq -r '.tag_name')"

   ### API BUSTED FALLBACK
   while true; do
      APPVERSION="$(curl -u $USER:$TOKEN -sX GET "${URL}" | jq -r '.tag_name')"
      if [[ $APPVERSION == null ]]; then
         log "*** we cant download the version, could be api related ***"
         log "*** sleeping now 300 secs ***"
         sleep 300
      else
         sleep 1 && break
      fi
   done

   ### CHECK LOCAL AND REMOTE
   while true; do

      if test -f "/tmp/LOCAL";then
         export LOCALVERSION="$(cat /tmp/LOCAL)"
      else
         export LOCALVERSION=0
      fi

      APPVERSION="$(curl -u $USER:$TOKEN -sX GET "${URL}" | jq -r '.tag_name')"
      if [[ $APPVERSION == $LOCALVERSION ]]; then
         sleep 8600
      else
         log "**** downloading dockserver ${APPVERSION} ****"
         if [[ `ls ${FOLDER}/apps/myapps/ | wc -l` -gt ${MINFILES} ]]; then
            apps
         else
            download
         fi
         echo $APPVERSION > /tmp/LOCAL
         sleep 1 && break
      fi
   done

   unwanted && perms
   looping
   unset FOLDER FOLDERTMP URL APPVERSION MINFILES GTHUB
   
done

}

### FUNCTION END
   ## RUN IN ORDER
   first
   build 
   run

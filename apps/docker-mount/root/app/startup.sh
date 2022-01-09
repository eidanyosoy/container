#!/usr/bin/with-contenv bash
# shellcheck shell=bash
#####################################
# All rights reserved.  #
# started from Zero  #
# Docker owned dockserver  #
# Docker Maintainer dockserver#
#####################################
#####################################
# THIS DOCKER IS UNDER LICENSE#
# NO CUSTOMIZING IS ALLOWED#
# NO REBRANDING IS ALLOWED #
# NO CODE MIRRORING IS ALLOWED#
#####################################
# shellcheck disable=SC2086
# shellcheck disable=SC2006

function log() {
   echo "[Mount] ${1}"
}

source /system/mount/mount.env
source /app/mount/function.sh

lang
LANGUAGE=${LANGUAGE}
startupmount=$(grep -Po '"startup.mount": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
log "${startupmount}"
run "${SCRIPT}"
sleep 120

while true; do
   if [ "$(ls -A ${REMOTE})" ] && [ "$(ps aux | grep -i 'rclone rc mount/mount' | grep -v grep)" != "" ]; then
      log "${startuprcloneworks}"
   else
      startup
   fi
   envrenew && lang && sleep 360 && checkban
done

#<EOF>#

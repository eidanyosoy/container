#!/usr/bin/with-contenv bash
# shellcheck shell=bash
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

if pidof -o %PPID -x "$0"; then
    exit 1
fi

source /system/mount/mount.env
source /app/mount/function.sh

mkdir -p "${TMPRCLONE}" "${REMOTE}"

rcdWAKEUP

while true; do
   if [ "$(ls -A /mnt/unionfs)" ] && [ "$(ps aux | grep -i 'rclone rc mount/mount' | grep -v grep)" != "" ]; then
      sleep 360
   else
      rckill && sleep 5 && rcx && refreshVFS && sleep 360
   fi
done

#EOF

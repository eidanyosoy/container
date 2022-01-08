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
path=/system/mount/logs

while true; do
  LSTATS=$(stat -c %s ${path}/rclone-union.log)
  if [[ ${LSTATS} -ge "2000" ]]; then $(command -v truncate) -s 0 ${path}/*.log; fi
  sleep 6h
done
#<EOF>#

#!/bin/bash
####################################
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
# shellcheck disable=SC2086
# shellcheck disable=SC2046
while true; do
   for removenzbs in `cat /config/sabnzbd.ini | grep "nzb_backup_dir" | cut -d. -f2 |awk '{print $3}'` ; do
      find $removenzbs -type f -name "*nzb*" -exec rm -rf \;
   done
   sleep 30m
   for removefailed in `cat /config/sabnzbd.ini | grep "complete_dir" | cut -d. -f2 |awk '{print $3}'` ; do
      find $removefailed -type d -name "*_FAILED*" -exec rm -rf \;
   done
   sleep 30m
   for setperms in `cat /config/sabnzbd.ini | grep "complete_dir" | cut -d. -f2 |awk '{print $3}'` ; do
      chown -cR 1000:1000 $setperms &>/dev/null
   done
   sleep 30m
done

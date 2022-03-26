#!/command/with-contenv bash
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
# shellcheck disable=SC2086
# shellcheck disable=SC2002
# shellcheck disable=SC2006

if pidof -o %PPID -x "$0"; then
   exit 1
fi

source /system/mount/mount.env
source /app/mount/function.sh

VFS_REFRESH=${VFS_REFRESH}

while true; do
   if [[ ! "${VFS_REFRESH}" ]]; then
      sleep 360
   else
      drivecheck
      truncate -s 0 ${RLOG}
      sleep "${VFS_REFRESH}"
   fi
done
#<EOF>#

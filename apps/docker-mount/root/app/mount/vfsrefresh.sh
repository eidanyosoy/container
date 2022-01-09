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
# shellcheck disable=SC2086
# shellcheck disable=SC2002
# shellcheck disable=SC2006

source /system/mount/mount.env
source /app/mount/function.sh
VFS_REFRESH=${VFS_REFRESH}

function drivecheck() {
  if [ "$(ls -A /mnt/unionfs)" ] && [ "$(ps aux | grep -i 'rclone rc mount/mount' | grep -v grep)" != "" ]; then
     rclone rc fscache/clear --fast-list --rc-user=${RC_USER} --rc-pass=${RC_PASSWORD} \
        --rc-addr=localhost:${RC_ADDRESS} --config=${CONFIG} --log-file=${RLOG} --log-level=${LOGLEVEL_RC}
     sleep 5
     rclone rc vfs/refresh recursive=true --fast-list \
        --rc-user=${RC_USER} --rc-pass=${RC_PASSWORD} --rc-addr=localhost:${RC_ADDRESS} \
        --config=${CONFIG} --log-file=${RLOG} --log-level=${LOGLEVEL_RC}
     truncate -s 0 ${RLOG}
  fi
}

while true; do
   if [[ ! "${VFS_REFRESH}" ]]; then
      sleep 60
   else
      drivecheck && sleep "${VFS_REFRESH}"
   fi
done
#<EOF>#

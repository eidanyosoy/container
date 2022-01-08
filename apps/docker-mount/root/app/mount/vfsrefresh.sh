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
ENV="/system/mount/mount.env"
VFS_REFRESH=${VFS_REFRESH}
source /system/mount/mount.env
config=/app/rclone/rclone.conf
log=/system/mount/logs/vfs-refresh.log

function drivecheck() {
   while true; do
     if [ "$(ls -A /mnt/unionfs)" ] && [ "$(ps aux | grep -i 'rclone rc mount/mount' | grep -v grep)" != "" ]; then
        rclone rc fscache/clear --fast-list --rc-user=${RC_USER} --rc-pass=${RC_PASSWORD} \
        --rc-addr=localhost:${RC_ADDRESS} --config=${config} --log-file=${log} --log-level=${LOGLEVEL_RC}
        sleep 5
        rclone rc vfs/refresh recursive=true --fast-list \
        --rc-user=${RC_USER} --rc-pass=${RC_PASSWORD} --rc-addr=localhost:${RC_ADDRESS} \
        --config=${config} --log-file=${log} --log-level=${LOGLEVEL_RC}
        truncate -s 0 ${log} && break
     else
        sleep 60 && break
     fi
   done
}
while true; do
   if [[ ! "${VFS_REFRESH}" ]]; then
      break
   else
      drivecheck && sleep "${VFS_REFRESH}" && continue
   fi
done
#<EOF>#
#<EOF>#
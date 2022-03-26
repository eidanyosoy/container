#!/command/with-contenv bash
# shellcheck shell=bash
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

function log() {
   echo "[Mount] ${1}"
}

if pidof -o %PPID -x "$0"; then
   exit 1
fi

source /system/mount/mount.env
source /app/mount/function.sh

lang && log "pulling language files" || { log "failed to pulling language files"; exit 1; }

LANGUAGE=${LANGUAGE}
startupmount=$(grep -Po '"startup.mount": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
log "${startupmount}"

mkdir -p "${TMPRCLONE}" "${REMOTE}" /mnt/remotes

rlog && log "starting logrotate" || { log "failed to starting logrotate"; exit 1; }
rcmount && log "starting rclone mount" || { log "failed to starting rclone mount"; exit 1; }
sleep 10
rcmergerfs && log "starting mergerfs" || { log "failed to starting mergerfs"; exit 1; }

testrun

#<EOF>#

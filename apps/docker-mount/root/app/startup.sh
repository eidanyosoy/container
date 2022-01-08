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

CONFIG=/app/rclone/rclone.conf
REMOTE=/mnt/unionfs
SMOUNT=/app/mount
JSONDIR=/system/mount/keys
GDSAMIN=4
ARRAY=$(ls -A ${JSONDIR} | egrep -c '*.json')
FDISCORD=/app/discord
LFOLDER=/app/language/mount
SDISCORD=/app/discord/discord.sh
LOG=/tmp/discord.dead
MLOG=/system/mount/logs/rclone-union.log
SMOUNT=/app/mount
SROTATE=/app/mount/rotation.sh
SCRIPT=/app/mount/mount.sh

function run() {
   bash "${1}"
}

function checkban() {
  tail -n 1 "${MLOG}" | grep --line-buffered 'googleapi: Error' | while read; do
     if [[ ! ${DISCORD_SEND} != "null" ]]; then discord ; else log "${startuphitlimit}" ; fi
     if [[ ${ARRAY} != 0 ]]; then run "${SROTATE}" && log "${startuprotate}" ; fi
   done
}

function rckill() {
   rclone rc mount/unmount \
   mountPoint=${REMOTE} \
   --config=${CONFIG} \
   --rc-user=${RC_USER} \
   --rc-pass=${RC_PASSWORD} \
   --rc-addr=${RC_ADDRESS}
}

function discord() {
   source /system/mount/mount.env
   DATE=$(date "+%Y-%m-%d")
   if [[ ${ARRAY} -gt 0 ]]; then
      MSG1=${startuphitlimit}
      MSG2=${startuprotate}
      MSGSEND="${MSG1} and ${MSG2}"
      rm -rf ${LOG}
   else
      MSG1=${startuphitlimit}
      MSGSEND="${MSG1}"
   fi
   YEAR=$(date "+%Y")
   if [[ ! -d "${FDISCORD}" ]]; then mkdir -p "${FDISCORD}"; fi
      if [[ ! -f "${SDISCORD}" ]]; then
         curl --silent -fsSL https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh -o "${SDISCORD}"
         chmod 755 "${SDISCORD}"
      fi
   if [[ ! -f "${LOG}" ]]; then
      run "${SDISCORD}" \
      --webhook-url=${DISCORD_WEBHOOK_URL} \
      --title "${DISCORD_EMBED_TITEL}" \
      --avatar "${DISCORD_ICON_OVERRIDE}" \
      --author "Dockerserver.io Bot" \
      --author-url "https://dockserver.io/" \
      --author-icon "https://dockserver.io/img/favicon.png" \
      --username "${DISCORD_NAME_OVERRIDE}" \
      --description "${MSGSEND}" \
      --thumbnail "https://www.freeiconspng.com/uploads/error-icon-4.png" \
      --footer "(c) ${YEAR} DockServer.io" \
      --footer-icon "https://www.freeiconspng.com/uploads/error-icon-4.png" \
      --timestamp >${LOG}
   fi
}

function envrenew() {
   file1=/system/mount/mount.env
   file2=/tmp/mount.env
   diff -q "$file1" "$file2"
   if [ $? -gt 0 ]; then
      rckill && run "${SCRIPT}"
    else
      echo "no changes" > /tmp/dead.lock
   fi
}

function lang() {
   source /system/mount/mount.env
   LANGUAGE=${LANGUAGE}
   startupmount=$(grep -Po '"startup.mount": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuphitlimit=$(grep -Po '"startup.hitlimit": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuprotate=$(grep -Po '"startup.rotate": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startupnewchanges=$(grep -Po '"startup.newchanges": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuprcloneworks=$(grep -Po '"startup.rcloneworks": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   currenttime=$(date +%H:%M)
   if [[ "$currenttime" > "23:59" ]] || [[ "$currenttime" < "00:01" ]]; then
      if [[ -d "/app/language" ]]; then
         git -C "${LFOLDER}/" stash --quiet && git -C "${LFOLDER}/" pull --quiet && cd "${LFOLDER}/" && git stash clear
      fi
   fi
   if [[ ! -d "/app/language" ]]; then mkdir -p "${LFOLDER}/" && git -C /app clone https://github.com/dockserver/language.git ; fi
}

function startup() {
   source /system/mount/mount.env
   rckill && run "${SCRIPT}"
}

source /system/mount/mount.env
lang
LANGUAGE=${LANGUAGE}
startupmount=$(grep -Po '"startup.mount": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
log "${startupmount}"
run "${SCRIPT}"
sleep 120

while true; do
   if [ "$(ls -A /mnt/unionfs)" ] && [ "$(ps aux | grep -i 'rclone rc mount/mount' | grep -v grep)" != "" ]; then
      log "${startuprcloneworks}"
   else
      startup
   fi
   envrenew && lang && sleep 360 && checkban
done

#<EOF>#

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
function run() {
   bash "${1}"
}

function checkban() {
   GDSAARRAY=$(ls -l ${JSONDIR} | egrep -c '*.json')
   MLOG=/system/mount/logs/rclone-union.log
   tail -n 1 "${MLOG}" | grep --line-buffered 'googleapi: Error' | while read; do
      if [[ ! ${DISCORD_SEND} != "null" ]]; then discord ; else log "${startuphitlimit}" ; fi
     if [[ ${GDSAARRAY} != 0 ]]; then run "${SROTATE}" && log "${startuprotate}" ; fi
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
   if [[ ${GDSAARRAY} != 0 ]]; then
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
      bash "${SDISCORD}" \
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
   RESULT=$?
   if [ $RESULT -gt 0 ]; then
      log "${startupnewchanges}" && rckill && run "${SCRIPT}"
    else
      rm -f /tmp/dead.lock && echo "no changes" | tee /tmp/dead.lock > /dev/null
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
      if [[ -d "/app/language" ]]; then git -C /app/language/ stash --quiet && git -C /app/language/ pull --quiet && cd /app/language/ && git stash clear ; fi
   fi
   if [[ ! -d "/app/language" ]]; then mkdir -p /app/language && git -C /app clone https://github.com/dockserver/language.git ; fi
}

function startup() {
   source /system/mount/mount.env
   rckill && run "${SCRIPT}"
}

#<COMMANDS>#
source /system/mount/mount.env
CONFIG=/app/rclone/rclone.conf
REMOTE=/mnt/unionfs
SMOUNT=/app/mount
JSONDIR=/system/mount/keys
GDSAMIN=1
FDISCORD=/app/discord
LFOLDER=/app/language/mount
SDISCORD=/app/discord/discord.sh
LOG=/tmp/discord.dead
SMOUNT=/app/mount
SROTATE=/app/mount/rotation.sh
SCRIPT=/app/mount/mount.sh

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
   envrenew && lang && sleep 360 && checkban && continue
done

#<EOF>#

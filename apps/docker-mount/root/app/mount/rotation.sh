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
function log() {
   echo "[ROTATION] ${1}"
}
if pidof -o %PPID -x "$0"; then
   exit 1
fi
if [[ ! -d "/system/mount/.keys" ]]; then
   mkdir -p /system/mount/.keys/
   chown -cR 1000:1000 /system/mount/.keys/
else
   chown -cR 1000:1000 /system/mount/.keys/
fi
if [[ ! -f /system/mount/.keys/lastkey ]]; then
   FMINJS=1
else
   FMINJS=$(cat /system/mount/.keys/lastkey)
fi
JSONDIR=/system/mount/keys
ARRAY=$(ls -l ${JSONDIR} | egrep -c '*.json')
MINJS=${FMINJS}
MAXJS=${ARRAY}
COUNT=$MINJS
CONFIG=/app/rclone/rclone.conf
if `ls -A ${JSONDIR} | grep "GDSA" &>/dev/null`;then
    export KEY=GDSA
elif `ls -A ${JSONDIR} | head -n1 | grep -Po '\[.*?]' | sed 's/.*\[\([^]]*\)].*/\1/' | sed '/GDSA/d'`;then
    export KEY=""
else
   log "no match found of GDSA[01=~100] or [01=~100]"
   sleep 20 && exit 0
fi

log "-->> We switch the ServiceKey to ${GDSA}${COUNT} "
IFS=$'\n'
filter="$1"
mapfile -t mounts < <(eval rclone listremotes --config=${CONFIG} | grep "$filter" | sed -e 's/://g' | sed '/ADDITIONAL/d'  | sed '/downloads/d'  | sed '/crypt/d' | sed '/gdrive/d' | sed '/union/d' | sed '/remote/d' | sed '/GDSA/d')
for i in ${mounts[@]}; do
   rclone config update $i service_account_file ${GDSA}$MINJS.json --config=${CONFIG}
   rclone config update $i service_account_file_path $JSONDIR --config=${CONFIG}
done
log "-->> Rotate to next ServiceKey done || MountKey is now ${GDSA}${COUNT} "
if [[ "${ARRAY}" -eq "${COUNT}" ]]; then
   COUNT=1
else
   COUNT=$(($COUNT >= $MAXJS ? MINJS : $COUNT + 1))
fi
COUNT=${COUNT}
echo "${COUNT}" >/system/mount/.keys/lastkey

log "-->> Next possible ServiceKey is ${GDSA}${COUNT} "

#<EOF>#

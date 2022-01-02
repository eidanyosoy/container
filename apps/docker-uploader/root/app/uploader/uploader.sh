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
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196

function log() {
    echo "${1}"
}

## check if script running > true exit
if pidof -o %PPID -x "$0"; then
    exit 1
fi

log "dockserver.io Multi-Thread Uploader started"
CONFIG=/system/servicekeys/rclonegdsa.conf

mkdir -p /system/uploader/logs/ \
         /system/uploader/json/
mkdir -p /system/uploader/json/{done,upload}

if `rclone config show --config=${CONFIG} | grep ":/encrypt" &>/dev/null`;then
  export CRYPTED=C
else
  export CRYPTED=""
fi

if ! `rclone config show --config=${CONFIG} | grep "local" &>/dev/null`;then
   rclone config create down local nunc 'true' --config=${CONFIG}
fi

if `rclone config show --config=${CONFIG} | grep "GDSA" &>/dev/null`;then
  export KEY=GDSA
elif `rclone config show --config=${CONFIG} | head -n1 | grep -Po '\[.*?]' | sed 's/.*\[\([^]]*\)].*/\1/' | sed '/GDSA/d'`;then
  export KEY=""
else
  log "no match found of GDSA[01=~100] or [01=~100]"
  sleep infinity
fi

KEYLOCAL=/system/servicekeys/keys/
ARRAY=($(ls -1v ${KEYLOCAL} | egrep '(PG|GD|GS|0)'))
COUNT=$(expr ${#ARRAY[@]} - 1)
if [[ -f "/system/uploader/.keys/lasteservicekey" ]]; then
  USED=$(cat /system/uploader/.keys/lasteservicekey)
  echo "${USED}" | tee /system/uploader/.keys/lasteservicekey > /dev/null
else
  USED=1 && echo "${USED}" | tee /system/uploader/.keys/lasteservicekey > /dev/null
fi

EXCLUDE=/system/uploader/rclone.exclude

if [[ ! -f ${EXCLUDE} ]]; then
   cat > ${EXCLUDE} << EOF; $(echo)
*-vpn/**
torrent/**
nzb/**
nzbget/**
.inProgress/**
jdownloader2/**
tubesync/**
aria/**
temp/**
qbittorrent/**
.anchors/**
sabnzbd/**
deluge/**
EOF
fi

LOGFILE=/system/uploader/logs
START=/system/uploader/json/upload
DONE=/system/uploader/json/done
DIFF=/system/uploader/logs/difflist.txt
CHK=/system/uploader/logs/check.log
DOWN=/mnt/downloads

while true;do 
   if [ "${USED}" -eq "${COUNT}" ]; then
      USED=1
   else
      USED=${USED}
   fi
   source /system/uploader/uploader.env
   DRIVEUSEDSPACE=${DRIVEUSEDSPACE}
   BANDWITHLIMIT=${BANDWITHLIMIT}
   SRC="down:${DOWN}"
   DRIVEPERCENT=$(df --output=pcent ${DOWN} | tr -dc '0-9')
   if [[ ! -z "${BANDWITHLIMIT}" ]];then BWLIMIT="";fi
   if [[ -z "${BANDWITHLIMIT}" ]];then BWLIMIT="--bwlimit=${BANDWITHLIMIT}";fi
   if [[ ! -z "${DRIVEUSEDSPACE}" ]]; then
      while true; do
        if [[ ${DRIVEPERCENT} -ge ${DRIVEUSEDSPACE} ]]; then
           sleep 1 && break
        else
           sleep 5 && continue
        fi
      done
   fi
   log "CHECKING DIFFMOVE FROM LOCAL TO REMOTE"
   rm -f "${CHK}" "${DIFF}"
   rclone check ${SRC} ${KEY}$[USED]${CRYPTED}: --min-age=${MIN_AGE_UPLOAD}m \
     --size-only --one-way --fast-list --config=${CONFIG} --exclude-from=${EXCLUDE} > "${CHK}" 2>&1
   awk 'BEGIN { FS = ": " } /ERROR/ {print $2}' "${CHK}" > "${DIFF}"
   awk 'BEGIN { FS = ": " } /NOTICE/ {print $2}' "${CHK}" >> "${DIFF}"
   sed -i '1d' "${DIFF}" && sed -i '/Encrypted/d' "${DIFF}" && sed -i '/Failed/d' "${DIFF}"
   num_files=`cat ${DIFF} | wc -l`
   if [ $num_files -gt 0 ]; then
      log "STARTING RCLONE MOVE from ${SRC} to REMOTE"
      sed '/^\s*#.*$/d' "${DIFF}" | \
      while IFS=$'\n' read -r -a UPP; do
        MOVE=${MOVE:-/}
        FILE=$(basename "${UPP[0]}")
        DIR=$(dirname "${UPP[0]}" | sed "s#${DOWN}/${MOVE}##g")
        SIZE=$(stat -c %s "${DOWN}/${UPP[0]}" | numfmt --to=iec-i --suffix=B --padding=7)
        STARTZ=$(date +%s)
        USED=${USED}
        echo "${DOWN}/${UPP[0]}" && touch "${LOGFILE}/${FILE}.txt"
        echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"logfile\": \"${LOGFILE}/${FILE}.txt\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\"}" >"${START}/${FILE}.json"
        rclone move "${DOWN}/${UPP[0]}" "${KEY}$[USED]${CRYPTED}:/${UPP[0]}" --config=${CONFIG} \
           --stats=10s --checkers=16 --use-json-log --use-mmap --update --no-traverse \
           --log-level=INFO --user-agent=${USERAGENT} ${BWLIMIT} --delete-empty-src-dirs \
           --log-file="${LOGFILE}/${FILE}.txt" --tpslimit 50 --tpslimit-burst 50
        ENDZ=$(date +%s)
        echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\",\"starttime\": \"${STARTZ}\",\"endtime\": \"${ENDZ}\"}" >"${DONE}/${FILE}.json"
        sleep 5
        tail -n 20 "${LOGFILE}/${FILE}.txt" | grep --line-buffered 'googleapi: Error' | while read; do
            USED=$(("${USED}" + 1))
            echo "${USED}" | tee "/system/uploader/.keys/lasteservicekey" > /dev/null
        done
        rm -f "${START}/${FILE}.json"   
        rm -f "${LOGFILE}/${FILE}.txt"
        chmod 755 "${DONE}/${FILE}.json"
      done
      log "DIFFMOVE FINISHED moving differential files from ${SRC} to REMOTE"
   else
      log "DIFFMOVE FINISHED skipped || less then 1 file"
      sleep 60
   fi
done

##E-o-F##
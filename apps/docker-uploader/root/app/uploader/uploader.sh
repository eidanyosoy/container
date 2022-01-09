#!/usr/bin/with-contenv bash
# shellcheck shell=bash
#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
function log() {
    echo "${1}"
}

if pidof -o %PPID -x "$0"; then exit 1; fi

log "dockserver.io Multi-Thread Uploader started"

BASE=/system/uploader
CONFIG=/system/servicekeys/rclonegdsa.conf
KEYLOCAL=/system/servicekeys/keys/
LOGFILE=/system/uploader/logs
START=/system/uploader/json/upload
DONE=/system/uploader/json/done
CHK=/system/uploader/logs/check.log
EXCLUDE=/system/uploader/rclone.exclude
LTKEY=/system/uploader/.keys/last
MAXT=730
MINSA=1
DIFF=1
CRYPTED=""
BWLIMIT=""
USERAGENT=""

mkdir -p "${LOGFILE}" "${START}" "${DONE}" 
find "${BASE}" -type f -name '*.log' -delete
find "${BASE}" -type f -name '*.txt' -delete
find "${START}" -type f -name '*.json' -delete

if `rclone config show --config=${CONFIG} | grep ":/encrypt" &>/dev/null`;then
   export CRYPTED=C
fi
if `rclone config show --config=${CONFIG} | grep "GDSA" &>/dev/null`;then
   export KEY=GDSA
elif `rclone config show --config=${CONFIG} | head -n1 | grep -Po '\[.*?]' | sed 's/.*\[\([^]]*\)].*/\1/' | sed '/GDSA/d'`;then
   export KEY=""
else
   log "no match found of GDSA[01=~100] or [01=~100]"
   sleep infinity
fi
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

ARRAY=$(ls -A ${KEYLOCAL} | wc -l )
MAXSA=${ARRAY}
if [[ ! -f "${LTKEY}" ]]; then touch "${LTKEY}" ; fi
USED=$(cat ${LTKEY})
if [[ "${USED}" != "" ]]; then USED=${USED} && echo "${USED}" > "${LTKEY}" ; else USED=${MINSA} && echo "${MINSA}" > "${LTKEY}" ; fi
if [[ "${USED}" -eq "${MAXSA}" ]]; then USED=$MINSA && DIFF=1 && echo "${USED}" > "${LTKEY}" ; fi

while true;do 
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}
   if [[ "${BANDWITHLIMIT}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then BWLIMIT="--bwlimit=${BANDWITHLIMIT}" ;fi
   if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      source /system/uploader/uploader.env
      while true; do 
         LCT=$(df --output=pcent ${DLFOLDER} | tail -n 1 | cut -d'%' -f1)
         if [ $DRIVEUSEDSPACE \> $LCT ]; then sleep 60 && continue ; else sleep 5 && break ; fi
      done
   fi
   rclone lsf --files-only --recursive --min-age="${MIN_AGE_FILE}" --format="p" --order-by="modtime" --config="${CONFIG}" --exclude-from="${EXCLUDE}" "${DLFOLDER}" > "${CHK}" 2>&1
   if [ `cat ${CHK} | wc -l` -gt 0 ]; then
      cat "${CHK}" | while IFS=$'\n' read -r -a UPP; do
         MOVE=${MOVE:-/}
         FILE=$(basename "${UPP[@]}")
         DIR=$(dirname "${UPP[@]}" | sed "s#${DLFOLDER}/${MOVE}##g")
         STARTZ=$(date +%s)
         USED=${USED}
         SIZE=$(stat -c %s "${DLFOLDER}/${UPP[@]}" | numfmt --to=iec-i --suffix=B --padding=7)
         while true;do
            SUMSTART=$(stat -c %s "${DLFOLDER}/${UPP[@]}") && sleep 5 && SUMTEST=$(stat -c %s "${DLFOLDER}/${UPP[@]}")
            if [[ "$SUMSTART" -eq "$SUMTEST" ]]; then sleep 1 && break ; else sleep 5 && continue ; fi
         done
         UPFILE=$(rclone size "${DLFOLDER}/${UPP[@]}" --config="${CONFIG}" --json | cut -d ":" -f3 | cut -d "}" -f1)
         touch "${LOGFILE}/${FILE}.txt"
            echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"logfile\": \"${LOGFILE}/${FILE}.txt\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\"}" > "${START}/${FILE}.json"
         rclone move "${DLFOLDER}/${UPP[@]}" "${KEY}$[USED]${CRYPTED}:/${DIR}/" --config="${CONFIG}" --stats=1s --checkers=32 --use-mmap --no-traverse --check-first \
          --drive-chunk-size=64M --log-level="${LOG_LEVEL}" --user-agent="${USERAGENT}" ${BWLIMIT} --log-file="${LOGFILE}/${FILE}.txt" --tpslimit 50 --tpslimit-burst 50
         ENDZ=$(date +%s)
            echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\",\"starttime\": \"${STARTZ}\",\"endtime\": \"${ENDZ}\"}" > "${DONE}/${FILE}.json"
         FILEGB=$(( $UPFILE/1024**3 ))
         DIFF=$(( $DIFF+$FILEGB ))
         source /system/uploader/uploader.env
         LCT=$(df --output=pcent ${DLFOLDER} | tail -n 1 | cut -d'%' -f1)
            if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
               if [ $DRIVEUSEDSPACE \> $LCT ]; then rm -rf "${CHK}" && DIFF=1 && sleep 5 && break ; fi
            fi
            if [[ "${USED}" -eq "${MAXSA}" ]]; then USED=$MINSA && DIFF=1 && echo "${USED}" > "${LTKEY}" ; fi
            if [ $MAXT \> $DIFF ]; then
               tail -n 20 "${LOGFILE}/${FILE}.txt" | grep --line-buffered 'googleapi: Error' | while read -r; do
                   USED=$(( $USED+$MINSA ))
                   if [[ "${USED}" -eq "${MAXSA}" ]];then USED=$MINSA && DIFF=1 && echo "${USED}" > "${LTKEY}" ; else echo "${USED}" > "${LTKEY}" ; fi
               done
            else
               DIFF=$DIFF
            fi
         rm -rf "${LOGFILE}/${FILE}.txt" && rm -rf "${START}/${FILE}.json" && chmod 755 "${DONE}/${FILE}.json"
      done
      log "MOVE FINISHED from ${DLFOLDER} to REMOTE"
   else
      log "MOVE skipped || less then 1 file" && sleep 180
   fi
done

##E-o-F##

#!/command/with-contenv bash
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

log "dockserver.io Multi-Thread Uploader started"

BASE=/system/uploader
CONFIG=/system/servicekeys/rclonegdsa.conf
CSV=/system/servicekeys/uploader.csv
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

cp ${CONFIG} /root/.config/rclone/rclone.conf &>/dev/null

mkdir -p "${LOGFILE}" "${START}" "${DONE}" 
find "${BASE}" -type f -name '*.log' -delete
find "${BASE}" -type f -name '*.txt' -delete
find "${START}" -type f -name '*.json' -delete


if test -f ${CONFIG}; then
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
fi

function loopcsv() {
CSV=/system/servicekeys/uploader.csv
if test -f ${CSV} ; then
   UPP=${UPP}
   MOVE=${MOVE:-/}
   FILE=$(basename "${UPP[1]}")
   DIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g")
   ENDCONFIG=/system/servicekeys/${UPP}.conf
   ARRAY=$(ls -A ${KEYLOCAL} | wc -l )
   USED=$(( $RANDOM % ${ARRAY} + 1 ))

   cat ${CSV} | grep -E ${DIR} | sed '/^\s*#.*$/d'| while IFS=$'|' read -ra myArray; do
   if [[ ${myArray[2]} == "" && ${myArray[3]} == "" ]]; then
   echo -e "\n
[${USED[0]}]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${JSONDIR}/${USED}
team_drive = ${myArray[1]}" >>$ENDCONFIG

else

ENC_PASSWORD=${myArray[2]}
ENC_SALT=${myArray[3]}
   echo -e "\n
[${USED[0]}]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${JSONDIR}/${USED}
team_drive = ${myArray[1]}
##
type = crypt
remote = ${USED[0]}:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = ${ENC_PASSWORD}
password2 = ${ENC_SALT}" >>$ENDCONFIG
   fi
done
fi

}

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

function rcloneupload() {

UPP=${UPP}
MOVE=${MOVE:-/}
DLFOLDER=${DLFOLDER}
FILE=$(basename "${UPP[1]}")
DIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g")
STARTZ=$(date +%s)
SIZE=$(stat -c %s "${DLFOLDER}/${UPP[1]}" | numfmt --to=iec-i --suffix=B --padding=7)

while true; do
  SUMSTART=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
  sleep 5
  SUMTEST=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
  if [[ "$SUMSTART" -eq "$SUMTEST" ]]; then
     sleep 1 && break
  else
     sleep 1 && continue
  fi
done

UPFILE=$($(which rclone) size "${DLFOLDER}/${UPP[1]}" --config="${CONFIG}" --json | cut -d ":" -f3 | cut -d "}" -f1)
touch "${LOGFILE}/${FILE}.txt"
ARRAY=$(ls -A ${KEYLOCAL} | wc -l )
USED=$(( $RANDOM % ${ARRAY} + 1 ))
  echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"logfile\": \"${LOGFILE}/${FILE}.txt\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\"}" > "${START}/${FILE}.json"

if test -f "/app/rclone/${UPP}.conf";then
   CONFIG=/system/servicekeys/${UPP}.conf
else
   CONFIG=/system/servicekeys/rclonegdsa.conf
fi

## RUN MOVE
$(which rclone) move "${DLFOLDER}/${UPP[1]}" "${KEY}$[USED]${CRYPTED}:/${DIR}/" --config="${CONFIG}" \
  --stats=1s --checkers=32 --use-mmap --no-traverse --check-first --drive-chunk-size=64M \
  --log-level="${LOG_LEVEL}" --user-agent="${USERAGENT}" ${BWLIMIT} --log-file="${LOGFILE}/${FILE}.txt" \
  --tpslimit 50 --tpslimit-burst 50 --min-age="${MIN_AGE_FILE}"

ENDZ=$(date +%s)
echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\",\"starttime\": \"${STARTZ}\",\"endtime\": \"${ENDZ}\"}" > "${DONE}/${FILE}.json"
## END OF MOVE
$(which rm) -rf "${LOGFILE}/${FILE}.txt" "${START}/${FILE}.json" 
$(which chmod) 755 "${DONE}/${FILE}.json"

if test -f "/app/rclone/${UPP}.conf";then
   $(which rm) -rf /system/servicekeys/${UPP}.conf
fi

}

## START HERE UPLOADER LIVE

while true; do
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}
   if [[ "${BANDWITHLIMIT}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then BWLIMIT="--bwlimit=${BANDWITHLIMIT}" ; fi
   if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      while true ; do 
        LCT=$(df --output=pcent ${DLFOLDER} --exclude={${DLFOLDER}/nzb,${DLFOLDER}/torrent,${DLFOLDER}/torrents} | tail -n 1 | cut -d'%' -f1)
        if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
          if [[ ! "${LCT}" -gt "${DRIVEUSEDSPACE}" ]]; then
             sleep 5 && break
          else
             sleep 30 && continue
          fi
        fi
      done
   fi
   $(which rclone) lsf --files-only -R --min-age="${MIN_AGE_FILE}" --config="${CONFIG}" --separator "|" --format="tp" --order-by="modtime" --exclude-from="${EXCLUDE}" "${DLFOLDER}" | sort  > "${CHK}" 2>&1
   if [ `cat ${CHK} | wc -l` -gt 0 ]; then
      TRANSFERS=${TRANSFERS:-2}
      ACTIVETRANSFERS=$(ls -1p ${LOGFILE} | wc -w)
      # shellcheck disable=SC2086
      cat "${CHK}" | while IFS=$'|' read -ra UPP; do
         while true ;do
           if [[ ! ${ACTIVETRANSFERS} -ge ${TRANSFERS} ]]; then
              sleep 1 && break
           else
              log "Already ${ACTIVETRANSFERS} transfers running, waiting for next loop"
              sleep 10 && continue
           fi
         done
         ## Looping to correct drive
         if test -f ${CSV} ; then
           loopcsv
         fi
         ## upload function startup
         rcloneupload
         ## upload function shutdown
         LCT=$(df --output=pcent ${DLFOLDER} --exclude={${DLFOLDER}/nzb,${DLFOLDER}/torrent} | tail -n 1 | cut -d'%' -f1)
         if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
            if [[ ! "${LCT}" -gt "${DRIVEUSEDSPACE}" ]]; then
               $(which rm) -rf "${CHK}" "${LOGFILE}/${FILE}.txt" "${START}/${FILE}.json" && \
               $(which chmod) 755 "${DONE}/${FILE}.json" && \
               break
            fi
         fi
      done
      $(which rm) -rf "${CHK}" && log "MOVE FINISHED from ${DLFOLDER} to REMOTE"
   else
      log "MOVE skipped || less then 1 file" && sleep 60
   fi
done

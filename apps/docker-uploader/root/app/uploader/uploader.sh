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
CSV=/system/servicekeys/uploader.csv
KEYLOCAL=/system/servicekeys/keys/
LOGFILE=/system/uploader/logs
START=/system/uploader/json/upload
DONE=/system/uploader/json/done
CHK=/system/uploader/logs/check.log
EXCLUDE=/system/uploader/rclone.exclude
CUSTOM=/app/custom

## FOR MAPPING CLEANUP

CONFIG=""
CRYPTED=""
BWLIMIT=""
USERAGENT=""

$(which mkdir) -p "${LOGFILE}" "${START}" "${DONE}" "${CUSTOM}" 
$(which find) "${BASE}" -type f -name '*.log' -delete
$(which find) "${BASE}" -type f -name '*.txt' -delete
$(which find) "${START}" -type f -name '*.json' -delete

## EXPORT THE KEY SPECS

if `ls -1p ${KEYLOCAL} | head -n1 | grep "GDSA" &>/dev/null`;then
    export KEY=GDSA
elif `ls -1p ${KEYLOCAL} | head -n1 | grep -Po '\[.*?]' | sed 's/.*\[\([^]]*\)].*/\1/' | sed '/GDSA/d'`;then
    export KEY=""
else
    log "no match found of GDSA[01=~100] or [01=~100]" && sleep infinity
fi

### EXCLUDE PART

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

##### FUNCTIONS

function loopcsv() {

   $(which mkdir) -p /app/custom/

if test -f ${CSV} ; then
   UPP=${UPP}
   MOVE=${MOVE:-/}

   FILE=$(basename "${UPP[1]}")
   # echo correct folder from log file
   DIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g" | cut -d ' ' -f 1 | sed 's|/.*||' )
   #
   ENDCONFIG=${CUSTOM}/${UPP}.conf
   ARRAY=$(ls -A ${KEYLOCAL} | wc -l )
   USED=$(( $RANDOM % ${ARRAY} + 1 ))

   $(which cat) ${CSV} | grep -E ${DIR} | sed '/^\s*#.*$/d'| while IFS=$'|' read -ra myArray; do

   if [[ ${myArray[2]} == "" && ${myArray[3]} == "" ]]; then
cat > ${ENDCONFIG} << EOF; $(echo)
## CUSTOM RCLONE.CONF
[${KEY}$[USED]]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${JSONDIR}/${KEY}$[USED]
team_drive = ${myArray[1]}
EOF

   else

cat > ${ENDCONFIG} << EOF; $(echo)
## CUSTOM RCLONE.CONF
[${KEY}$[USED]]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${JSONDIR}/${KEY}$[USED]
team_drive = ${myArray[1]}
##
[${KEY}$[USED]C]
type = crypt
remote = ${KEY}$[USED]:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = ${myArray[2]}
password2 = ${myArray[3]}
EOF
   fi
   done
fi

}

function rcloneupload() {

   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}

   UPP=${UPP}
   MOVE=${MOVE:-/}
   FILE=$(basename "${UPP[1]}")
   DIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g")
   STARTZ=$(date +%s)
   SIZE=$(stat -c %s "${DLFOLDER}/${UPP[1]}" | numfmt --to=iec-i --suffix=B --padding=7)

   for (( ; ; ))
   do
      SUMSTART=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
      sleep 5
      SUMTEST=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
      if [[ "$SUMSTART" -eq "$SUMTEST" ]]; then
         sleep 1 && break
      else
         sleep 1
      fi
   done
   if test -f "${CUSTOM}/${UPP}.conf" ; then
      CONFIG=${CUSTOM}/${UPP}.conf && \
        USED=`rclone listremotes --config=${CONFIG} | grep "$1" | sed -e 's/://g' | sed -e 's/GDSA//g' | sort`
   else
      CONFIG=/system/servicekeys/rclonegdsa.conf && \
        ARRAY=$(ls -A ${KEYLOCAL} | wc -l ) && \
          USED=$(( $RANDOM % ${ARRAY} + 1 ))
   fi

   ## CRYPTED HACK
   if `rclone config show --config=${CONFIG} | grep ":/encrypt" &>/dev/null`;then
       export CRYPTED=C
   else
       export CRYPTED=""
   fi

   touch "${LOGFILE}/${FILE}.txt" && \
   echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"logfile\": \"${LOGFILE}/${FILE}.txt\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\"}" > "${START}/${FILE}.json"

   if [[ "${BANDWITHLIMIT}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      BWLIMIT="--bwlimit=${BANDWITHLIMIT}"
   fi

   ## RUN MOVE
   $(which rclone) move "${DLFOLDER}/${UPP[1]}" "${KEY}$[USED]${CRYPTED}:/${DIR}/" \
      --config="${CONFIG}" \
      --stats=1s \
      --checkers=32 \
      --use-mmap \
      --no-traverse \
      --check-first \
      --drive-chunk-size=64M \
      --log-level="${LOG_LEVEL}" \
      --user-agent="${USERAGENT}" ${BWLIMIT} \
      --log-file="${LOGFILE}/${FILE}.txt" \
      --tpslimit 50 \
      --tpslimit-burst 50 \
      --min-age="${MIN_AGE_FILE}"
   ENDZ=$(date +%s)
   echo "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\",\"starttime\": \"${STARTZ}\",\"endtime\": \"${ENDZ}\"}" > "${DONE}/${FILE}.json"

   unset CRYPTED
   ## END OF MOVE
   $(which rm) -rf "${LOGFILE}/${FILE}.txt" \
                   "${START}/${FILE}.json" 
   $(which chmod) 755 "${DONE}/${FILE}.json"
   if test -f "${CUSTOM}/${UPP}.conf";then
      $(which rm) -rf ${CUSTOM}/${UPP}.conf
   fi

}

## START HERE UPLOADER LIVE

for (( ; ; ))
do
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}

   if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      for (( ; ; ))
      do
        LCT=$(df --output=pcent ${DLFOLDER} --exclude={${DLFOLDER}/nzb,${DLFOLDER}/torrent,${DLFOLDER}/torrents} | tr -dc '0-9')
        if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
           if [[ "${LCT}" -gt "${DRIVEUSEDSPACE}" ]]; then
              sleep 5 && break
          else
              sleep 5
          fi
        fi
      done
   fi

   #### RCLONE LIST FILE
   $(which rclone) lsf "${DLFOLDER}" \
      --files-only -R \
      --min-age="${MIN_AGE_FILE}" \
      --separator "|" \
      --format="tp" \
      --order-by="modtime" \
      --exclude-from="${EXCLUDE}" | sort  > "${CHK}" 2>&1

   #### FIRST LOOP
   if [ `cat ${CHK} | wc -l` -gt 0 ]; then
      # shellcheck disable=SC2086
      cat "${CHK}" | while IFS=$'|' read -ra UPP; do
         while true; do
           source /system/uploader/uploader.env
           ## -I [ exclude check.log files ]
           ACTIVETRANSFERS=$(ls -A ${LOGFILE} -I "check.log" | wc -l)
           TRANSFERS=${TRANSFERS:-2}
           if [[ ${ACTIVETRANSFERS} -lt ${TRANSFERS} ]]; then
              sleep t
              ## REMOVE ACTIVE UPLOAD from check file
              ## to prevent double upload trying 
              sed -i -e '1 w /dev/stdout' -e '1d' "${CHK}" &>/dev/null
              FILE=$(basename "${UPP[1]}")
              touch "${LOGFILE}/${FILE}.txt" 
              ## for correct reading of activities 
              break
           else
              sleep 10
           fi
         done

         ## Looping to correct drive
         if test -f ${CSV}; then loopcsv ; fi

         ## upload function startup
         rcloneupload & ## DEMONISED UPLOAD
         ## upload function shutdown

         LCT=$(df --output=pcent ${DLFOLDER} --exclude={${DLFOLDER}/nzb,${DLFOLDER}/torrent,${DLFOLDER}/torrents} | tr -dc '0-9')
         if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
            if [[ "${DRIVEUSEDSPACE}" -gt "${LCT}" ]]; then
               $(which rm) -rf "${CHK}" \
                               "${LOGFILE}/${FILE}.txt" \
                               "${START}/${FILE}.json" && \
               $(which chmod) 755 "${DONE}/${FILE}.json" && \
               break
            fi
         fi
      done
      $(which rm) -rf "${CHK}" && \
         log "MOVE FINISHED from ${DLFOLDER} to REMOTE"
   else
      log "MOVE skipped || less then 1 file" && \
         sleep 60
   fi
done

## END OF FILE

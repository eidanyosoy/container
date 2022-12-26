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
source /system/uploader/uploader.env
#SETTINGS
ENVA=/system/uploader/uploader.env
CSV=/system/servicekeys/uploader.csv
UPPED=/system/uploader/.keys/used
EXCLUDE=/system/uploader/rclone.exclude
ENDCONFIG=/app/rclone/rclone.conf
DATABASE=/system/uploader/db/uploader.db
PAUSE=/app/rclone/pause

#FOLDER
BASE=/system/uploader
JSONDIR=/system/servicekeys/keys
JSONUSED=/system/uploader/.keys/keys
LOGFILE=/system/uploader/logs
SUNION=/mnt/unionfs
CUSTOM=/app/custom
LFOLDER=/app/language/uploader
ARRAY=$($(which ls) -A "${JSONDIR}" | $(which wc) -l)

#FOR MAPPING CLEANUP
CONFIG=""
CRYPTED=""
BWLIMIT=""
USERAGENT=""

#########################################
# From here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
function log() {
   GRAY="\033[0;37m"
   BLUE="\033[0;34m"
   NC="\033[0m"
   $(which echo) -e "${GRAY}[$($(which date) +'%Y/%m/%d %H:%M:%S')]${BLUE} [Uploader]${NC} ${1}"
}

function refreshVFS() {
   source /system/uploader/uploader.env
   #### SEND VFS REFRESH TO MOUNT ####
   if [[ "${VFS_REFRESH_ENABLE}" == "true" ]]; then
      readarray -t VFSMOUNT < <($(which awk) -F',' '{ for( i=1; i<=NF; i++ ) print $i }' <<<"${MOUNT}")
      for ENTRY in "${VFSMOUNT[@]}"; do
         STATUSCODE=$($(which curl) --silent --output /dev/null --write-out "%{http_code}" "${ENTRY}")
         if [[ "${STATUSCODE}" == "200" ]]; then
            $(which curl) -fs -X POST "${ENTRY}/vfs/forget?dir=${DIR}&_async=true" &>/dev/null
            $(which curl) -fs -X POST "${ENTRY}/vfs/refresh?dir=${DIR}&recursive=true&_async=true" &>/dev/null
         fi
      done
   fi
}

function autoscan() {
   source /system/uploader/uploader.env
   #### TRIGGER AUTOSCAN ####
   if [[ "${AUTOSCAN_URL}" != "null" ]]; then
      if [[ "${AUTOSCAN_USER}" == "null" ]]; then
         STATUSCODE=$($(which curl) --silent --output /dev/null --write-out "%{http_code}" "${AUTOSCAN_URL}/triggers/manual")
      else
         STATUSCODE=$($(which curl) --silent --output /dev/null --write-out "%{http_code}" -u "${AUTOSCAN_USER}:${AUTOSCAN_PASS}" "${AUTOSCAN_URL}/triggers/manual")
            if [[ "${STATUSCODE}" == "200" ]]; then
               if [[ "${AUTOSCAN_USER}" == "null" ]]; then
                  $(which curl) -sfG -X POST --data-urlencode "dir=${SUNION}/${DIR}" "${AUTOSCAN_URL}/triggers/manual"
               else
                  $(which curl) -sfG -X POST -u "${AUTOSCAN_USER}:${AUTOSCAN_PASS}" --data-urlencode "dir=${SUNION}/${DIR}" "${AUTOSCAN_URL}/triggers/manual"
               fi
            fi
      fi
   fi
}

function notification() {
   source /system/uploader/uploader.env
   #### CHECK NOTIFICATION TYPE ####
   if [[ "${NOTIFYTYPE}" == "" ]]; then
     NOTIFYTYPE="info"
   fi
   #### CHECK NOTIFICATON SERVERNAME ####
   if [[ "${NOTIFICATION_SERVERNAME}" == "null" ]]; then
     NOTIFICATION_NAME="Docker"
   else
     NOTIFICATION_NAME="${NOTIFICATION_SERVERNAME}"
   fi
   #### SEND NOTIFICATION ####
   if [[ "${NOTIFICATION_URL}" != "null" ]]; then
      log "${MSG}" && apprise --notification-type="${NOTIFYTYPE}" --title="Uploader - ${NOTIFICATION_NAME}" --body="${MSGAPP}" "${NOTIFICATION_URL}/?format=markdown"
   else
      log "${MSG}"
   fi
}

function checkerror() {
   source /system/uploader/uploader.env
   CHECKERROR=$($(which cat) "${LOGFILE}/${FILE}.txt" | $(which grep) -E -wi "Failed|ERROR|Source doesn't exist or is a directory and destination is a file|The filename or extension is too long|file name too long|Filename too long")
   DATEDIFF="$(( ${ENDZ} - ${STARTZ} ))"
   HOUR="$(( ${DATEDIFF} / 3600 ))"
   MINUTE="$(( (${DATEDIFF} % 3600) / 60 ))"
   SECOND="$(( ${DATEDIFF} % 60 ))"
   UPLOADENDTIME=$($(which date) -d @${ENDZ} '+%d.%m.%Y %H:%M:%S')
   #### TIMESPENT FOR NOTIFICATION ####
   if [[ "${HOUR}" == "0" ]]; then
      if [[ "${MINUTE}" == "0" ]]; then
         TIMESPENT="${SECOND}s"
      fi
      if [[ "${MINUTE}" != "0" ]]; then
         TIMESPENT="${MINUTE}m ${SECOND}s"
      fi
   else
      TIMESPENT="${HOUR}h ${MINUTE}m ${SECOND}s"
   fi
   #### CHECK ERROR ON UPLOAD ####
   if [[ "${CHECKERROR}" != "" ]]; then
      STATUS="0"
      ERROR=$($(which cat) "${LOGFILE}/${FILE}.txt" | $(which grep) -E -wi "Failed|ERROR|Source doesn't exist or is a directory and destination is a file|The filename or extension is too long|file name too long|Filename too long" | $(which head) -n 1 | $(which tr) -d '"')
      NOTIFYTYPE="failure"
      if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]] || [[ ${NOTIFICATION_LEVEL} == "ERROR" ]]; then
         MSG="-> ❌ Upload failed ${FILE} with Error ${ERROR} <-"
         MSGAPP="### ❌ Upload failed
${FILE}
#### Folder
${DRIVE}
#### Error
${ERROR}" && notification
      fi
   else
      STATUS="1"
      ERROR="NULL"
      NOTIFYTYPE="success"
      if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]]; then
         MSG="-> ✅ Upload successful ${FILE} with Size ${SIZE} <-"
         MSGAPP="### ✅ Upload successful
${FILE}
#### File Size
${SIZE}
#### Folder
${DRIVE}
#### Upload Date/Time
${UPLOADENDTIME}
#### Elapsed Time
${TIMESPENT}" && notification
      fi
   fi
}

function lang() {
   source /system/uploader/uploader.env
   startupuploader=$($(which jq) ".startup.uploaderdb" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupnginx=$($(which jq) ".startup.nginx" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupphp=$($(which jq) ".startup.php" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   limitused=$($(which jq) ".limit.used" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   uploaderstart=$($(which jq) ".uploader.start" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   uploaderend=$($(which jq) ".uploader.end" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
}

function cleanuplog() {
   source /system/uploader/uploader.env
   #### REMOVE ENTRIES OLDER THAN ${LOG_RETENTION_DAYS} IN DATABASE ####
   if [[ "${LOG_RETENTION_DAYS}" != "null" ]]; then
      if [[ "${LOG_RETENTION_DAYS}" != +([0-9.]) ]]; then
         LOG_RETENTION_DAYS="30"
      else
         LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS}"
      fi
      ENDTIME=$($(which date) --date "-${LOG_RETENTION_DAYS} days" +%s)
      $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; DELETE FROM completed_uploads WHERE endtime < ${ENDTIME};" | $(which sqlite3) "${DATABASE}" &>/dev/null
   #### REMOVE LAST ${LOG_ENTRY} ENTRIES IN DATABASE ####
   else
      if [[ "${LOG_ENTRY}" != +([0-9.]) ]]; then
         LOG_ENTRY="1000"
      else
         LOG_ENTRY="${LOG_ENTRY}"
      fi
      $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; DELETE FROM completed_uploads WHERE endtime NOT IN (SELECT endtime from completed_uploads ORDER BY endtime DESC LIMIT ${LOG_ENTRY});" | $(which sqlite3) "${DATABASE}" &>/dev/null
   fi
}

function loopcsv() {
   $(which mkdir) -p "${CUSTOM}"
   if [[ -f "${CSV}" ]]; then
      #### ECHO CORRECT FOLDER FROM LOG FILE ####
      FILE="${UPP[3]}"
      DRIVE=$($(which echo) "${UPP[1]}" | $(which sed) 's/-//g')
      #### USE FILE NAME AS RCLONE CONF ####
      CUSTOMCONFIG="${CUSTOM}/${FILE}.conf"
      TOKEN=$($(which rclone) config dump --config="${SOURCECONFIG}" | $(which jq) -r 'to_entries | (.[] | select(.value.type=="dropbox")) | .value.token' | $(which head) -n 1)
      #### TEST IS FOLDER AND CSV CORRECT ####
      $(which cat) "${CSV}" | $(which sed) '/^\s*#.*$/d' | $(which grep) -Ew "${DRIVE}" | while IFS=$'|' read -ra CHECKDIR; do
         if [[ ${CHECKDIR[0]} == ${DRIVE} ]]; then
           $(which cat) "${CSV}" | $(which sed) '/^\s*#.*$/d' | $(which grep) -Ew "${DRIVE}" | while IFS=$'|' read -ra UPPDIR; do
           if [[ "${UPPDIR[2]}" == "" && "${UPPDIR[3]}" == "" ]]; then
              $(which rclone) config create DB dropbox token="${TOKEN}" --config="${CUSTOMCONFIG}" --non-interactive &>/dev/null
           else
              if [[ "${HASHPASSWORD}" == "plain" && "${HASHPASSWORD}" != "hashed" ]]; then
                 ENC_PASSWORD=$($(which rclone) obscure "${UPPDIR[2]}" | $(which tail) -n1)
                 ENC_SALT=$($(which rclone) obscure "${UPPDIR[3]}" | $(which tail) -n1)
              else
                 ENC_PASSWORD="${UPPDIR[2]}"
                 ENC_SALT="${UPPDIR[3]}"
              fi
              $(which rclone) config create DB dropbox token="${TOKEN}" --config="${CUSTOMCONFIG}" --non-interactive &>/dev/null
              $(which rclone) config create DBC crypt remote=DB:/encrypt filename_encryption=standard directory_name_encryption=true password="${ENC_PASSWORD}" password2="${ENC_SALT}" --config="${CUSTOMCONFIG}" &>/dev/null
           fi
           done
         fi
      done
   fi
}

function replace-used() {
   #### CREATE USED FILE ####
   if [[ ! -f "${UPPED}" ]]; then
      $(which echo) "0" > "${UPPED}"
   fi
   USEDUPLOAD=$($(which cat) "${UPPED}")
   #### UPDATE USED FILE ####
   NEWVALUE="$(( ${USEDUPLOAD} + ${SIZEBYTES} ))"
   $(which echo) "${NEWVALUE}" > "${UPPED}"
}

function reset-used() {
   #### SORT KEYS TO DEFAULT ####
   if [[ ! -f "${JSONUSED}" ]]; then
      $(which ls) -A "${JSONDIR}" | $(which sort) -V > "${JSONUSED}"
   else
      $(which rm) -f "${JSONUSED}" && $(which ls) -A "${JSONDIR}" | $(which sort) -V > "${JSONUSED}"
   fi
   #### UPDATE KEY IN ${ENDCONFIG} AND SET USED TO ZERO ####
   KEY=$($(which sed) -n 1p "${JSONUSED}")
   $(which rclone) config update DB service_account_file="${JSONDIR}/${KEY}" --config="${ENDCONFIG}" &>/dev/null
   $(which echo) "0" > "${UPPED}"
}

function rcloneupload() {
   source /system/uploader/uploader.env
   FILE="${UPP[3]}"
   DIR="${UPP[2]}"
   SETDIR=$($(which echo) "${UPP[2]}" | $(which cut) -d/ -f-"${FOLDER_DEPTH}")
   DRIVE="${UPP[1]}"
   SIZEBYTES="${UPP[4]}"
   SIZE=$($(which echo) "${UPP[4]}" | $(which numfmt) --to=iec-i --suffix=B)

   #### CHECK IS FILE AVAILABLE ####
   if [[ ! -f "${DLFOLDER}/${DIR}/${FILE}" ]]; then
      $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; DELETE FROM uploads WHERE filebase = \"${FILE}\";" | $(which sqlite3) "${DATABASE}" &>/dev/null
      $(which sleep) 2 && return
   fi
   #### CHECK IS FILE SIZE NOT CHANGED ####
   SIZETEST=$($(which stat) -c %s "${DLFOLDER}/${DIR}/${FILE}")
   if [[ "${SIZEBYTES}" -ne "${SIZETEST}" ]] || [[ "${SIZETEST}" -ne "${SIZEBYTES}" ]]; then
      while true; do
         SUMSTART=$($(which stat) -c %s "${DLFOLDER}/${DIR}/${FILE}")
         $(which sleep) 5
         SUMTEST=$($(which stat) -c %s "${DLFOLDER}/${DIR}/${FILE}")
         if [[ "${SUMSTART}" -eq "${SUMTEST}" ]] || [[ "${SUMTEST}" -eq "${SUMSTART}" ]]; then
            #### WHEN FILE SIZE A IS EQUAL TO B THEN BREAK LOOP ###
            SIZEBYTES=$($(which stat) -c %s "${DLFOLDER}/${DIR}/${FILE}")
            SIZE=$($(which stat) -c %s "${DLFOLDER}/${DIR}/${FILE}" | $(which numfmt) --to=iec-i --suffix=B)
            $(which sleep) 2 && break
         else
            #### WHEN FILE SIZE A IS NOT EQAUL TO B THEN LOOP AGAIN TO CHECK THE FILE SIZE ####
            $(which sleep) 10
         fi
      done
   fi
   #### PERMISSIONS STATS COMMANDS ####
   SUSER=$($(which stat) -c %u "${DLFOLDER}/${DIR}/${FILE}")
   PERMI=$($(which stat) -c %a "${DLFOLDER}/${DIR}/${FILE}")
   #### SET PERMISSIONS BACK TO UID 1000 AND 755 FOR UI READING ###
   if [[ "${SUSER}" != "$PUID" ]]; then
      $(which chown) abc:abc -R "${DLFOLDER}/${DIR}/${FILE}" &>/dev/null 
   fi
   if [[ "${PERMI}" != "755" ]]; then
      $(which chmod) 0755 -R "${DLFOLDER}/${DIR}/${FILE}" &>/dev/null
   fi
   #### CHECK IS CUSTOM RCLONE.CONF IS AVAILABLE ####
   if [[ -f "${CUSTOM}/${FILE}.conf" ]]; then
      CONFIG="${CUSTOM}/${FILE}.conf"
   else
      CONFIG="${ENDCONFIG}"
   fi
   #### REPLACED UPLOADED FILESIZE ####
   replace-used
   #### CRYPTED HACK ####
   CHECKCRYPTED=$($(which rclone) config dump --config="${CONFIG}" | $(which jq) -r 'to_entries | (.[] | select(.value.type=="crypt")) | .key')
   if [[ "${CHECKCRYPTED}" == "" ]]; then
      CRYPTED=""
   else
      CRYPTED="C"
   fi
   #### CHECK USED KEY ####
   KEYNOTI="DB"
   #### TOUCH LOG FILE FOR UI READING ####
   touch "${LOGFILE}/${FILE}.txt" &>/dev/null
   #### UPDATE DATABASE ENTRY ####
   $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; INSERT OR REPLACE INTO uploads (drive,filedir,filebase,filesize,logfile,gdsa) VALUES (\"${DRIVE}\",\"${DIR}\",\"${FILE}\",\"${SIZE}\",\"${LOGFILE}/${FILE}.txt\",\"${KEYNOTI}${CRYPTED}\");" | $(which sqlite3) "${DATABASE}" &>/dev/null
   #### READ BWLIMIT ####
   if [[ "${BANDWIDTH_LIMIT}" == "" ]]; then
      BANDWIDTH_LIMIT="null"
   fi
   if [[ "${BANDWIDTH_LIMIT}" != "null" ]]; then
      BWLIMIT="--bwlimit=${BANDWIDTH_LIMIT}"
   fi
   #### CHECK IS TRANSFERS GREAT AS 1 TO PREVENT DOUBLE FOLDER ON GOOGLE ####
   if [[ "${TRANSFERS}" -gt "1" ]]; then
      #### MAKE FOLDER ON CORRECT DRIVE #### 
      $(which rclone) mkdir "DB${CRYPTED}:/${DIR}/" --config="${CONFIG}" &>/dev/null
   fi
   #### GENERATE FOR EACH UPLOAD A NRW AGENT ####
   USERAGENT=$($(which cat) /dev/urandom | $(which tr) -dc 'a-zA-Z0-9' | $(which fold) -w 32 | $(which head) -n 1)
   #### START TIME UPLOAD ####
   STARTZ=$($(which date) +%s)
   #### RUN RCLONE UPLOAD COMMAND ####
   $(which rclone) moveto "${DLFOLDER}/${DIR}/${FILE}" "DB${CRYPTED}:/${DIR}/${FILE}" \
      --config="${CONFIG}" \
      --stats=1s --checkers=4 \
      --drive-chunk-size=32M \
      --log-level="${LOG_LEVEL}" \
      --user-agent="${USERAGENT}" ${BWLIMIT} \
      --log-file="${LOGFILE}/${FILE}.txt" \
      --tpslimit 20 &>/dev/null
   #### END TIME UPLOAD ####
   ENDZ=$($(which date) +%s)
   #### SEND TO AUTOSCAN DOCKER ####
   autoscan
   #### SEND REFRESH AND FORGET TO MOUNT DOCKER ####
   refreshVFS
   #### CHECK UPLOAD ####
   checkerror
   #### ECHO END-PARTS FOR UI READING ####
   $(which find) "${DLFOLDER}/${SETDIR}" -mindepth 1 -type d -empty -delete &>/dev/null
   $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; INSERT INTO completed_uploads (drive,filedir,filebase,filesize,gdsa,starttime,endtime,status,error) VALUES (\"${DRIVE}\",\"${DIR}\",\"${FILE}\",\"${SIZE}\",\"${KEYNOTI}${CRYPTED}\",\"${STARTZ}\",\"${ENDZ}\",\"${STATUS}\",\"${ERROR}\"); DELETE FROM uploads WHERE filebase = \"${FILE}\";" | $(which sqlite3) "${DATABASE}" &>/dev/null
   #### END OF MOVE ####
   $(which rm) -rf "${LOGFILE}/${FILE}.txt" &>/dev/null
   #### REMOVE CUSTOM RCLONE.CONF ####
   if [[ -f "${CUSTOM}/${FILE}.conf" ]]; then
      $(which rm) -rf "${CUSTOM}/${FILE}.conf" &>/dev/null
   fi
}

function listfiles() {
   source /system/uploader/uploader.env
   #### FIND NEW FILES ####
   IFS=$'\n'
   mapfile -t "FILEBASE" < <($(which find) "${DLFOLDER}" -type f -size +0b -cmin +"${MIN_AGE_UPLOAD}" -printf "%P\n" | $(which grep) -Evf "${EXCLUDE}")
   for NAME in ${FILEBASE[@]}; do
      LISTFILE=$($(which basename) "${NAME}")
      LISTDIR=$($(which dirname) "${NAME}")
      LISTDRIVE=$($(which echo) "${LISTDIR}" | $(which cut) -d/ -f-"${FOLDER_DEPTH}" | $(which xargs) -I {} $(which basename) {})
      LISTSIZE=$($(which stat) -c %s "${DLFOLDER}/${NAME}" 2>/dev/null)
      $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; INSERT OR IGNORE INTO upload_queue (drive,filedir,filebase,filesize) SELECT \"${LISTDRIVE}\",\"${LISTDIR}\",\"${LISTFILE}\",\"${LISTSIZE}\" WHERE NOT EXISTS (SELECT 1 FROM uploads WHERE filebase = \"${LISTFILE}\");" | $(which sqlite3) "${DATABASE}" &>/dev/null
   done
}

function checkspace() {
   source /system/uploader/uploader.env
   #### CHECK DRIVEUSEDSPACE ####
   if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      while true; do
        LCT=$($(which df) --output=pcent "${DLFOLDER}" | tr -dc '0-9')
        if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
           if [[ "${LCT}" -ge "${DRIVEUSEDSPACE}" ]]; then
              $(which sleep) 2 && break
           else
              $(which sleep) 10
           fi
        fi
      done
   fi
}

function transfercheck() {
   while true; do
      source /system/uploader/uploader.env
      #### RUN PAUSE CHECK ####
      pausecheck
      #### START TRANSFER CHECK ####
      ACTIVETRANSFERS=$($(which echo) "SELECT COUNT(*) FROM uploads;" | $(which sqlite3) -readonly "${DATABASE}" 2>/dev/null)
      if [[ "${TRANSFERS}" != +([0-9.]) ]] || [ "${TRANSFERS}" -gt "99" ] || [ "${TRANSFERS}" -eq "0" ]; then
         TRANSFERS="1"
      else
         TRANSFERS="${TRANSFERS}"
      fi
      if [[ "${ACTIVETRANSFERS}" -lt "${TRANSFERS}" ]]; then
         #### CREATE DATABASE ENTRY ####
         $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; DELETE FROM upload_queue WHERE filebase = \"${UPP[3]}\"; INSERT INTO uploads (filebase) VALUES (\"${UPP[3]}\");" | $(which sqlite3) "${DATABASE}" &>/dev/null
         $(which sleep) 2 && break
      else
         $(which sleep) 10
      fi
   done
}

function pausecheck() {
   while true; do
      if [[ ! -f "${PAUSE}" ]]; then
         $(which sleep) 2 && break
      else
         $(which sleep) 10
      fi
   done
}

#### START HERE UPLOADER ####
function startuploader() {
   while true; do
      #### RUN CHECK SPACE ####
      checkspace
      #### RUN LIST FILES ####
      listfiles
      #### START UPLOAD ####
      source /system/uploader/uploader.env
      CHECKFILES=$($(which echo) "SELECT COUNT(*) FROM upload_queue;" | $(which sqlite3) -readonly "${DATABASE}" 2>/dev/null)
      if [[ "${CHECKFILES}" -ge "1" ]]; then
         # shellcheck disable=SC2086
         #### CHECK FOLDER PRIORITY ####
         if [[ "${FOLDER_PRIORITY}" != "null" ]]; then
            i=0
            ORDER_BY="ORDER BY CASE drive "
            readarray -t FOLDERP < <($(which awk) -F',' '{ for( i=1; i<=NF; i++ ) print $i }' <<<"${FOLDER_PRIORITY}")
            for ENTRY in "${FOLDERP[@]}"; do
               ORDER_BY+="WHEN '${ENTRY}' THEN ${i} "
               ((i+=1))
            done
            ORDER_BY+="ELSE ${i} END, time"
            SEARCHSTRING="${ORDER_BY}"
         else
            SEARCHSTRING="ORDER BY time"
         fi
         $(which echo) "SELECT * FROM upload_queue ${SEARCHSTRING} LIMIT 1;" | $(which sqlite3) -readonly "${DATABASE}" 2>/dev/null | while IFS='|' read -ra UPP; do
            #### TO CHECK IS IT A FILE OR NOT ####
            if [[ -f "${DLFOLDER}/${UPP[2]}/${UPP[3]}" ]]; then
               #### REPULL SOURCE FILE FOR LIVE EDITS ####
               source /system/uploader/uploader.env
               #### RUN TRANSFERS CHECK ####
               transfercheck
               #### CHECK IS CSV AVAILABLE AND LOOP TO CORRECT DRIVE ####
               #if [[ -f "${CSV}" ]]; then 
               #   loopcsv
               #fi
               #### UPLOAD FUNCTIONS STARTUP ####
               if [[ "${TRANSFERS}" -eq "1" ]]; then 
                  #### SINGLE UPLOAD ####
                  rcloneupload
               else
                  #### DEMONISED UPLOAD ####
                  rcloneupload &
               fi
            else
               #### WHEN NOT THEN DELETE ENTRY ####
               $(which echo) "PRAGMA busy_timeout = 10000; PRAGMA synchronous = NORMAL; DELETE FROM upload_queue WHERE filebase = \"${UPP[3]}\";" | $(which sqlite3) "${DATABASE}" &>/dev/null
               $(which sleep) 2
            fi
         done
         #### CLEANUP COMPLETED HISTORY ####
         cleanuplog
      else
         #### SLEEP REDUCES CPU AND RAM USED ####
         $(which sleep) 120
      fi
   done
}

#### END OF FILE ####

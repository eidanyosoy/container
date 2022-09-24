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
UPPED=/system/servicekeys/uploaded.json
KEYLOCAL=/system/servicekeys/keys
LOGFILE=/system/uploader/logs
START=/system/uploader/json/upload
DONE=/system/uploader/json/done
CHK=/system/uploader/logs/check.log
EXCLUDE=/system/uploader/rclone.exclude
CUSTOM=/app/custom

#### FOR MAPPING CLEANUP ####
CONFIG=""
CRYPTED=""
BWLIMIT=""
USERAGENT=""

#### REMOVE LEFT OVER ####
$(which mkdir) -p "${LOGFILE}" "${START}" "${DONE}" "${CUSTOM}"
$(which find) "${BASE}" -type f -name '*.log' -delete
$(which find) "${BASE}" -type f -name '*.txt' -delete
$(which find) "${START}" -type f -name '*.json' -delete

#### EXPORT THE KEY SPECS ####
if `ls -1p ${KEYLOCAL} | head -n1 | grep "GDSA" &>/dev/null`;then
    export KEY=GDSA
elif `ls -1p ${KEYLOCAL} | head -n1 | grep -Po '\[.*?]' | sed 's/.*\[\([^]]*\)].*/\1/' | sed '/GDSA/d'`;then
    export KEY=""
else
    log "no match found of GDSA[01=~100] or [01=~100]" && sleep infinity
fi

#### EXCLUDE PART ####
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

#### START OF ALL FUNCTIONS ####
function cleanuplog() {
   RMLOG=/system/uploader/logs/rmcheck.log
   #### RCLONE LIST FILE ####
   $(which rclone) lsf "${DONE}" --files-only -R -s "|" -F "tp" | sort -n > "${RMLOG}" 2>&1
   #### REMOVE LAST 1000 FILES ####
   if [ `cat ${RMLOG} | wc -l` -gt 1000 ]; then
      #### PRINT TOTAL LINE NUMBER ####
      line_count=`awk 'END{print NR}' ${RMLOG}`
      ##### EXCLUDE LAST 1000 LINES ####
      remove_line=`expr $line_count - 1000`
      ##### REMOVE EVERYTHING EXCEPT LAST 1000 LINES ####
      $(which sed) -i '1,'$remove_line'd' ${RMLOG}
      ##### REMOVE LEFT OVER FROM RMLOG FILE WHEN OVER 1000 FILES ####
      $(which cat) "${RMLOG}" | while IFS=$'|' read -ra RMLO; do
          $(which rm) -rf "${DONE}/${RMLO[1]}" &>/dev/null
      done
   else
      $(which rm) -rf "${RMLOG}" "${CHK}" &>/dev/null
   fi
}

function loopcsv() {
$(which mkdir) -p /app/custom/
if test -f ${CSV} ; then
   #### ECHO CORRECT FOLDER FROM LOG FILE ####
   DIR=${SETDIR}
   FILE=${FILE}
   ENDCONFIG=${CUSTOM}/${FILE}.conf
   #### USE FILE NAME AS RCLONE CONF ####
   ARRAY=$(ls ${KEYLOCAL} | wc -l )
   USED=$(( $RANDOM % ${ARRAY} + 1 ))

   ### TEST IS FOLDER AND CSV CORRECT ####
   $(which cat) ${CSV} | grep -Ew ${DIR} | sed '/^\s*#.*$/d'| while IFS=$'|' read -ra CHECKDIR; do
     if [[ ${CHECKDIR[0]} == ${DIR} ]]; then
        $(which cat) ${CSV} | grep -Ew ${DIR} | sed '/^\s*#.*$/d'| while IFS=$'|' read -ra uppdir; do
        if [[ ${uppdir[2]} == "" && ${uppdir[3]} == "" ]]; then
### UNENCRYPTED RCLONE.CONF ####
cat > ${ENDCONFIG} << EOF; $(echo)
## CUSTOM RCLONE.CONF for ${FILE}
[${KEY}$[USED]]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${KEYLOCAL}/${KEY}$[USED]
team_drive = ${uppdir[1]}
EOF
     else
#### CRYPTED CUSTOM RCLONE.CONF ####
cat > ${ENDCONFIG} << EOF; $(echo)
## CUSTOM RCLONE.CONF
[${KEY}$[USED]]
type = drive
scope = drive
server_side_across_configs = true
service_account_file = ${KEYLOCAL}/${KEY}$[USED]
team_drive = ${uppdir[1]}
##
[${KEY}$[USED]C]
type = crypt
remote = ${KEY}$[USED]:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = ${uppdir[2]}
password2 = ${uppdir[3]}
EOF
        fi
        done
     fi
   done
fi
}

# Replace the line of the given line number with the given replacement in the given file.
function replace-used() {

   #### CHECK IS CUSTOM RCLONE.CONF IS AVAILABLE ####
   if test -f "${CUSTOM}/${FILE}.conf" ; then
      CONFIG=${CUSTOM}/${FILE}.conf && \
        USED=`$(which rclone) listremotes --config="${CONFIG}" | grep "$1" | sed -e 's/://g' | sed -e 's/GDSA//g' | sort`
   else
      CONFIG=/system/servicekeys/rclonegdsa.conf && \
        ARRAY=$($(which ls) ${KEYLOCAL} | wc -l) && \
          USED=$(( $RANDOM % ${ARRAY} + 1 ))
   fi
   #### PUSH INFORMATION TO FILE ####
   USEDKEY=$($(which cat) "${UPPED}" | jq -r '.KEY')
   USEDUPLOADGB=$($(which cat) "${UPPED}" | jq -r '.USED')                                                                    
   if [[ ${USEDKEY} =~ '^[0-9][0-9]+$' ]];then
      USEDKEY=${KEY}
   fi                             
   if [[ $(date +%H:%M) == "00:01" ]]; then
      USEDUPLOADGB=0
   elif [[ ${USEDUPLOADGB} == null ]];then
       USEDUPLOADGB=0      
   else
      USEDUPLOADGB=$($(which cat) "${UPPED}" | jq -r '.USED')
   fi
   NEWVALUE=$(( ${USEDUPLOADGB} + ${SIZE}))
   echo '{"KEY" : "'${KEY}'","USED" : "'${NEWVALUE}'"}' | jq . > "${UPPED}"

}

function rcloneupload() {
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}
   MOVE=${MOVE:-/}
   FILE=$(basename "${UPP[1]}")
   DIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g")
   SIZE=$(stat -c %s "${DLFOLDER}/${UPP[1]}" | numfmt --to=iec-i --suffix=B --padding=7)

   #### PERMISSIONS STATS COMMANDS ####
   #### FILE TO UPLOAD ####
   SUSER=$(stat -c %u "${DLFOLDER}/${UPP[1]}")
   PERMI=$(stat -c %a "${DLFOLDER}/${UPP[1]}")
   #### CHECK IS FILE SIZE NOT CHANGE ####
   while true ; do
      SUMSTART=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
      $(which sleep) 5
      SUMTEST=$(stat -c %s "${DLFOLDER}/${UPP[1]}")
      if [ "$SUMTEST" -eq 0 ] || [ "$SUMSTART" -eq 0 ]; then
         #### WHEN FILE SIZE A IS ZERO AND FILES SIZE B IS ZERO LOOP AND WAIT ####
         $(which sleep) 5
         #### FIX FOR 0 BYTE UPLOADS ###£
      elif [ "$SUMSTART" -eq "$SUMTEST" ] || [ "$SUMTEST" -eq "$SUMSTART" ]; then
         #### WHEN FILE SIZE A IS EQUAL TO B THEN BREAK LOOP ###
         $(which sleep) 2 && break
      else
         #### WHEN FILE SIZE A IS NOT EQAUL TO B THEN LOOP AGAIN TO CHECK THE FILE SIZE ####
         $(which sleep) 10
      fi
   done
   #### SET PERMISSIONS BACK TO UID 1000 AND 755 FOR UI READING ###
   if [ ! "$SUSER" = "$PUID" ];then
      $(which chown) abc:abc -R "${DLFOLDER}/${UPP[1]}" &>/dev/null 
   fi
   if [ ! "$PERMI" = "755" ];then
      $(which chmod) 0755 -R "${DLFOLDER}/${UPP[1]}" &>/dev/null
   fi
   #### CHECK IS CUSTOM RCLONE.CONF IS AVAILABLE ####
   ##if test -f "${CUSTOM}/${FILE}.conf" ; then
   ##   CONFIG=${CUSTOM}/${FILE}.conf
   ##else
   ##   CONFIG=/system/servicekeys/rclonegdsa.conf && \
   ##fi
   #### CHECK IS CUSTOM RCLONE.CONF IS AVAILABLE ####
   if test -f "${CUSTOM}/${FILE}.conf" ; then
      CONFIG=${CUSTOM}/${FILE}.conf && \
        USED=`$(which rclone) listremotes --config="${CONFIG}" | grep "$1" | sed -e 's/://g' | sed -e 's/GDSA//g' | sort`
   else
      CONFIG=/system/servicekeys/rclonegdsa.conf && \
        ARRAY=$($(which ls) ${KEYLOCAL} | wc -l) && \
          USED=$(( $RANDOM % ${ARRAY} + 1 ))
   fi
   #### REPLACED UPLOADED FILESIZE ####
   #### replace-used
   #### CRYPTED HACK ####
   if `$(which rclone) config show --config="${CONFIG}" | grep ":/encrypt" &>/dev/null`;then
       export CRYPTED=C
   else
       export CRYPTED=""
   fi
   #### TOUCH LOG FILE FOR UI READING ####
   touch "${LOGFILE}/${FILE}.txt" && \
      $(which echo) "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"logfile\": \"${LOGFILE}/${FILE}.txt\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\"}" > "${START}/${FILE}.json"
   #### READ BWLIMIT ####
   if [[ "${BANDWITHLIMIT}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      BWLIMIT="--bwlimit=${BANDWITHLIMIT}"
   fi
   #### CHECK IS TRANSFERS GREAT AS 1 TO PREVENT DOUBLE FOLDER ON GOOGLE ####
   if [[ "${TRANSFERS}" != 1 ]];then
      #### MAKE FOLDER ON CORRECT DRIVE #### 
      $(which rclone) mkdir "${KEY}$[USED]${CRYPTED}:/${DIR}/" --config="${CONFIG}"
   fi
   #### GENERATE FOR EACH UPLOAD A NRW AGENT ####
   USERAGENT=$($(which cat) /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
   #### START TIME UPLOAD ####
   STARTZ=$(date +%s)
   #### RUN RCLONE UPLOAD COMMAND ####
   $(which rclone) moveto "${DLFOLDER}/${UPP[1]}" "${KEY}$[USED]${CRYPTED}:/${DIR}/${FILE}" \
      --config="${CONFIG}" \
      --stats=1s --checkers=2 \
      --drive-chunk-size=8M \
      --log-level="${LOG_LEVEL}" \
      --user-agent="${USERAGENT}" ${BWLIMIT} \
      --log-file="${LOGFILE}/${FILE}.txt" \
      --tpslimit 20
   #### END TIME UPLOAD ####
   ENDZ=$(date +%s)
   #### ECHO END-PARTS FOR UI READING ####
   $(which find) "${DLFOLDER}/${SETDIR}" -type d -empty -delete &>/dev/null
   $(which echo) "{\"filedir\": \"${DIR}\",\"filebase\": \"${FILE}\",\"filesize\": \"${SIZE}\",\"gdsa\": \"${KEY}$[USED]${CRYPTED}\",\"starttime\": \"${STARTZ}\",\"endtime\": \"${ENDZ}\"}" > "${DONE}/${FILE}.json"
   #### UNSET CRYPTED WHEN USED CRYPTED KEYS ####
   unset CRYPTED
   #### END OF MOVE ####
   $(which rm) -rf "${LOGFILE}/${FILE}.txt" "${START}/${FILE}.json"
   #### LOG FILES ON SERVER ####
   SLOGFILE=$(stat -c %u "${DONE}/${FILE}.json")
   PERMILOG=$(stat -c %a "${DONE}/${FILE}.json")
   #### SET PERMISSIONS BACK TO UID 1000 AND 755 FOR UI READING ###
   if [ ! "$SLOGFILE" = "$PUID" ];then
      $(which chown) abc:abc -R "${DONE}/${FILE}.json" &>/dev/null 
   fi
   if [ ! "$PERMILOG" = "755" ];then
      $(which chmod) 755 -R "${DONE}/${FILE}.json" &>/dev/null
   fi
   #### REMOVE CUSTOM RCLONE.CONF ####
   if test -f "${CUSTOM}/${FILE}.conf";then
      $(which rm) -rf ${CUSTOM}/${FILE}.conf
   fi
}

function listfiles() {
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}
   #### RCLONE LIST FILE ####
   $(which rclone) lsf "${DLFOLDER}" --files-only -R -s "|" -F "tp" --exclude-from="${EXCLUDE}" | sort -n > "${CHK}" 2>&1
}

function checkspace() {
   source /system/uploader/uploader.env
   DLFOLDER=${DLFOLDER}
   #### CHECK DRIVEUSEDSPACE ####
   if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
      while true ; do
        LCT=$($(which df) --output=pcent ${DLFOLDER} | tr -dc '0-9')
        if [[ "${DRIVEUSEDSPACE}" =~ ^[0-9][0-9]+([.][0-9]+)?$ ]]; then
           if [[ "${LCT}" -ge "${DRIVEUSEDSPACE}" ]]; then
              $(which sleep) 5 && break
           else
              $(which sleep) 10
           fi
        fi
      done
   fi
}

function transfercheck() {
   FILE=${SETFILE}
   while true ; do
      source /system/uploader/uploader.env
      ACTIVETRANSFERS=`ls ${LOGFILE} | egrep -c "*.txt"`
      TRANSFERS=${TRANSFERS:-2}
      if [ '^[0-9][0-9]+$' == "${TRANSFERS}" ] || [ "${TRANSFERS}" -gt 99 ] || [ "${TRANSFERS}" -eq 0 ];then
         TRANSFERS=1
      else
         TRANSFERS=${TRANSFERS:-2}
      fi
      if [[ "${ACTIVETRANSFERS}" -lt "${TRANSFERS}" ]]; then
         #### REMOVE ACTIVE UPLOAD FROM CHECK FILE ####
         $(which touch) "${LOGFILE}/${FILE}.txt"
         if test -f "${DLFOLDER}/${UPP[1]}" ; then
            #### CHANGE MODTIME OF FILE ####
            $(which touch) -m "${DLFOLDER}/${UPP[1]}"
         fi
         #### RELOAD CHECK FILE ####
         listfiles
         $(which sleep) 5 && break
      else
         $(which sleep) 10
      fi
   done
}

function rclonedown() {
   source /system/uploader/uploader.env
   CHECKFILES=$($(which cat) ${CHK} | wc -l)
   #### SHUTDOWN UPLOAD LOOP WHEN TP UPLOAD IS LESS THEN "${TRANSFERS}" ####
   if [[ "${CHECKFILES}" -eq "${TRANSFERS}" ]]; then
      $(which rm) -rf "${CHK}" "${LOGFILE}/${FILE}.txt" "${START}/${FILE}.json" && \
      $(which chown) abc:abc -R "${DONE}/${FILE}.json" &>/dev/null && \
      $(which chmod) 755 -R "${DONE}" &>/dev/null
   #### SHUTDOWN UPLOAD LOOP WHEN DRIVE SPACE IS LESS THEN SETTINGS ####
   LCT=$($(which df) --output=pcent ${DLFOLDER} | tr -dc '0-9')
   elif [[ "${DRIVEUSEDSPACE}" =~ '^[0-9][0-9]+([.][0-9]+)?$' ]]; then
      if [[ "${DRIVEUSEDSPACE}" -ge "${LCT}" ]]; then
         $(which rm) -rf "${CHK}" "${LOGFILE}/${FILE}.txt" "${START}/${FILE}.json" && \
         $(which chown) abc:abc -R "${DONE}/${FILE}.json" &>/dev/null && \
         $(which chmod) 755 -R "${DONE}/${FILE}.json" &>/dev/null
      fi
   else
      sleep 3
   fi
}

#### END OF ALL FUNCTIONS ####

#### START HERE UPLOADER LIVE
while true ; do
   #### RUN CHECK SPACE ####
   checkspace
   #### RUN LIST COMMAND-FUNCTION ####
   listfiles
   #### FIRST LOOP ####
   source /system/uploader/uploader.env
   CHECKFILES=$($(which cat) ${CHK} | wc -l)
   if [ "${CHECKFILES}" -ge "${TRANSFERS}" ] || [ "${CHECKFILES}" -eq "${TRANSFERS}" ]; then
      # shellcheck disable=SC2086
      $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra UPP; do
         #### TO CHECK IS IT A FILE OR NOT ####
         if test -f "${DLFOLDER}/${UPP[1]}"; then
            #### REPULL SOURCE FILE FOR LIVE EDITS ####
            source /system/uploader/uploader.env
            #### RUN TRANSFERS CHECK ####
            SETFILE=$(basename "${UPP[1]}")     
            transfercheck
            #### SET CORRECT FOLDER FOR CUSTOM UPLOAD RCLONE.CONF ####
            SETDIR=$(dirname "${UPP[1]}" | sed "s#${DLFOLDER}/${MOVE}##g" | cut -d ' ' -f 1 | sed 's|/.*||' )
            #### CHECK IS CSV AVAILABLE AND LOOP TO CORRECT DRIVE ####
            if test -f ${CSV}; then loopcsv ; fi
            #### UPLOAD FUNCTIONS STARTUP ####
            CHECKFILES=$($(which cat) ${CHK} | wc -l)
            ACTIVETRANSFERS=`ls ${LOGFILE} | egrep -c "*.txt"`
            if [ "${CHECKFILES}" -eq "${TRANSFERS}" ] || [ "${CHECKFILES}" -lt "${TRANSFERS}" ]; then
               #### FALLBACK TO SINGLE UPLOAD ####
               rcloneupload
            elif [ "${ACTIVETRANSFERS}" -lt "${TRANSFERS}" ] || [ "${CHECKFILES}" -gt "${TRANSFERS}"]; then
               #### DEMONISED UPLOAD ####
               rcloneupload &
            else
               #### SINGLE UPLOAD ####
               rcloneupload
            fi
            #### SHUTDOWN RCLONE UPLOAD PROCESS ####
            rclonedown
         else
            #### WHEN NOT THEN SLEEP 1 SEC ####
            sleep 1
         fi
      done
      #### CLEANUP OLD JSON FILES WHEN OVER 1000 FILES ####
      cleanuplog
   else
      #### SLEEP REDUCES CPU AND RAM USED ####
      sleep 120
   fi
done

#### END OF FILE ####

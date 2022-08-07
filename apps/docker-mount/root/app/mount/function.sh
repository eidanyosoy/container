#!/command/with-contenv bash
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
# shellcheck disable=SC2086
# shellcheck disable=SC2002
# shellcheck disable=SC2006
## FUNCTIONS SOURCECONFIG ##
#########################################
# From here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
source /system/mount/mount.env
#SETTINGS
CONFIG=/app/rclone/rclone.conf
ENVA=/system/mount/mount.env
TMPENV=/tmp/mount.env
GDSAMIN=4
ARRAY=$(ls -A ${JSONDIR} | wc -l )

#SCRIPTS
SDISCORD=/app/discord/discord.sh

#FOLDER
REMOTE=/mnt/unionfs
JSONDIR=/system/mount/keys
JSONUSED=/system/mount/.keys/.usedkeys
SMOUNT=/app/mount
FDISCORD=/app/discord
LFOLDER=/app/language/mount

#LOG
MLOG=/system/mount/logs/rclone-union.log
RLOG=/system/mount/logs/vfs-refresh.log
CLOG=/system/mount/logs/vfs-clean.log
DLOG=/tmp/discord.dead

RCD="$(which rclone) rc --rc-addr=0.0.0.0:8554"

#########################################
# From here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
function log() {
   echo -e "[Mount] ${1}"
}

function checkban() {
   ### RELOAD ENF FILE ###
   source /system/mount/mount.env

   RCCHECK=$($RCD core/stats | jq -r '. | .lastError' | grep -E '403')
   if [ $? = 0 ]; then
      if [[ ! ${DISCORD_SEND} != "null" ]]; then discord ; fi
      if [[ ! ${DISCORD_SEND} == "null" ]]; then log "${startuphitlimit}" ; fi
      if [[ `ls -A ${JSONDIR} | wc -l` -gt 4 ]]; then
         [[ -f "/system/mount/.keys/lastkey" ]] && $(which rm) -rf /system/mount/.keys/lastkey
         [[ ! -d "/system/mount/.keys" ]] && $(which mkdir) -p /system/mount/.keys/
         [[ -d "/system/mount/.keys" ]] && $(which chown) -cR 1000:1000 /system/mount/.keys/ &>/dev/null
         RCERROR=$($RCD core/stats | jq -r '. | .lastError')
         RemoteList=$($RCD config/dump | jq -r 'to_entries | (.[] | select(.value.team_drive)) | .key')
            while IFS= read -r remote; do
               newServiceAccount=$($(which find) ${JSONDIR}/*.json -type f | shuf -n 1)
               echo "$newServiceAccount" > ${JSONUSED}
               log "Rclone claims ${RCERROR}, switching to service account ${newServiceAccount} for remote ${remote}"
               $RCD backend/command command=set fs=${remote}: -o service_account_file=${newServiceAccount} -o service_account_path=${JSONDIR}
            done <<< "$RemoteList"
         $(which cp) -r /app/rclone/rclone.conf /root/.config/rclone/ && sleep 5
         ### RESET STATS AFTER SWITCH THE KEY ###
         $RCD core/stats-reset &>/dev/null
         ### RESET ALL LOGS AFTER SWITCH ###
         $(which truncate) -s 0 /system/mount/logs/*.log &>/dev/null
     fi
   fi
}

function discord() {
   source /system/mount/mount.env
   DATE=$(date "+%Y-%m-%d")
   YEAR=$(date "+%Y")
   SOURCE='https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh'
   if [[ ${ARRAY} -gt 0 ]]; then
       MSG1=${startuphitlimit}
       MSG2=${startuprotate}
       MSGSEND="${MSG1} and ${MSG2}"
       $(which rm) -rf ${DLOG}
   else
       MSG1=${startuphitlimit}
       MSGSEND="${MSG1}"
   fi
   [[ ! -d "${FDISCORD}" ]] && \
      $(which mkdir) -p "${FDISCORD}"
   [[ ! -f "${SDISCORD}" ]] && \
      $(which curl) --silent -fsSL "${SOURCE}" -o "${SDISCORD}" && chmod 755 "${SDISCORD}"
   [[ ! -f "${DLOG}" ]] && \
      $(which bash) "${SDISCORD}" \
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
      --timestamp > "${DLOG}"
}

function lang() {
   LANGUAGE=${LANGUAGE}
   [[ ! -d "/app/language" ]] && $(which git) config --global --add safe.directory /app/language && $(which git) -C /app clone --quiet https://github.com/dockserver/language.git
   startupmount=$(grep -Po '"startup.mount": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuphitlimit=$(grep -Po '"startup.hitlimit": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuprotate=$(grep -Po '"startup.rotate": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startupnewchanges=$(grep -Po '"startup.newchanges": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
   startuprcloneworks=$(grep -Po '"startup.rcloneworks": *\K"[^"]*"' "${LFOLDER}/${LANGUAGE}.json" | sed 's/"\|,//g')
}

function rlog() {
  SIZE=$(du /system/mount/logs/ | cut -f 1)
  ## 200MB max size of file
  if [[ $SIZE -gt 200000 ]]; then $(which truncate) -s 0 /system/mount/logs/*.log &>/dev/null ; fi
}

function folderunmount() {
for fod in /mnt/* ;do
    basename "$fod" >/dev/null
    FOLDER="$(basename -- $fod)"
    IFS=- read -r <<< "$ACT"
    if ! ls -1p "$fod/" >/dev/null ; then
       $(which fusermount) -uzq /mnt/$FOLDER && log "unmounting $FOLDER" || log "failed to unmounting $FOLDER"
    fi
done
}

function rcmount() {
[[ -f "/tmp/rclone.sh" ]] && $(which rm) -rf /tmp/*.sh
source /system/mount/mount.env
export MLOG=/system/mount/logs/rclone-union.log
[[ -f "${ECLOG}" ]] && $(which rm) -rf "${ECLOG}"

$(which cp) -r "$ENVA" "$TMPENV"

CONFIG=/app/rclone/rclone.conf
if [[ "$(ls -1p /mnt/remotes)" ]] ; then
   log " cleanup from rclone cache | please wait"
   $(which rm) -rf /mnt/rclone_cache/*
   if [ $? -gt 0 ]; then log " cleanup finished " ; fi
fi

cat > /tmp/rclone.sh << EOF; $(echo)
#!/command/with-contenv bash
# shellcheck shell=bash
# auto generated

### remove test file
[[ -f "/tmp/rclone.running" ]] && $(which rm) -f /tmp/rclone.running

$(which fusermount) -uzq /mnt/unionfs
$(which fusermount) -uzq /mnt/remotes
RCD="$(which rclone) rc --rc-addr=0.0.0.0:8554"

### START WEBUI
$(which rclone) rcd \\
  --config=${CONFIG} \\
  --log-file=${MLOG} \\
  --log-level=${LOGLEVEL} \\
  --user-agent=${UAGENT} \\
  --cache-dir=${TMPRCLONE} \\
  --human-readable \\
  --track-renames \\
  --track-renames-strategy modtime,leaf \\
  --buffer-size=64M \\
  --rc-no-auth \\
  --rc-allow-origin=* \\
  --rc-addr=0.0.0.0:8554 \\
  --rc-web-gui \\
  --rc-web-gui-force-update \\
  --rc-web-gui-no-open-browser &
  ### \\--rc-web-fetch-url=https://api.github.com/repos/controlol/rclone-webui/releases/latest &

sleep 5
## SIMPLE START MOUNT
${RCD} mount/mount \\
  fs=remote: mountPoint=/mnt/remotes \\
  mountType=mount vfsOpt='{"CacheMode": 2, "GID": 1000, "UID": 1000, "Umask": 0}' mountOpt='{"AllowOther": true}'

sleep 5
### SET MAJOR OPTIONS FOR MOUNT : ${RCD} options/set options/set --json 
${RCD} options/set --json {'"main": { "TPSLimitBurst": 20, "TPSLimit": 20 , "Checkers": 6, "Transfers": 6, "BufferSize": 16777216, "TrackRenames": true, "TrackRenamesStrategy":"modtime,leaf", "NoUpdateModTime": true, "BufferSize": 67108864, "UserAgent": "rclone_mount", "CutoffMode":"hard", "Progress":true, "UseMmap":true, "HumanReadable":true}'} > /dev/null
${RCD} options/set --json {'"vfs": { "GID": '1000', "UID": '1000', "CacheMode": 1, "Umask": 0, "CacheMaxSize": 322122547200, "CacheMaxAge": 3600000000000, "CacheMaxSize": 322122547200, "CachePollInterval": 300000000000, "ChunkSize": 67108864, "ChunkSizeLimit": 536870912, "ReadAhead": 67108864, "NoModTime": true,"NoChecksum": true, "WriteBack": 300000000000,"CaseInsensitive": true, "ReadAhead": 2147483648}'} > /dev/null 
${RCD} options/set --json {'"mount": { "AllowNonEmpty": true, "AllowOther": true, "AsyncRead": true, "WritebackCache": true}'} > /dev/null

touch /tmp/rclone.running
EOF
echo $(date) > /tmp/rclone.running
###

## SET PERMISSIONS 
[[ -f "/tmp/rclone.sh" ]] && \
   $(which chmod) 755 /tmp/rclone.sh && \
   $(which bash) /tmp/rclone.sh

while true; do
  if [ "$(ls -1p /mnt/remotes)" ]; then break; else sleep 5 ; fi
done
}

function rcmergerfs() {
source /system/mount/mount.env
if [[ -d "${ADDITIONAL_MOUNT}" ]];then
   UFSPATH="/mnt/downloads=RW:${ADDITIONAL_MOUNT}=${ADDITIONAL_MOUNT_PERMISSION}:/mnt/remotes=NC"
else
   UFSPATH="/mnt/downloads=RW:/mnt/remotes=NC"
fi
###
MGFS="allow_other,rw,async_read=true,statfs_ignore=nc,use_ino,func.getattr=newest,category.action=all,category.create=mspmfs,cache.writeback=true,cache.symlinks=true,cache.files=auto-full,dropcacheonclose=true,nonempty,minfreespace=0,fsname=mergerfs"
## TO RUN JUST ONCE
if ! $(which pgrep) -x "mergerfs" > /dev/null; then
   $(which mergerfs) -o ${MGFS} ${UFSPATH} /mnt/unionfs &>/dev/null
fi
}

function refreshVFS() {
source /system/mount/mount.env
log ">> run vfs refresh <<"
for fod in /mnt/remotes/* ;do
    basename "$fod" >/dev/null
    FOLDER="$(basename -- $fod)"
    IFS=- read -r <<< "$ACT"
      log " VFS refreshing : $FOLDER"
      $RCD vfs/forget dir=$FOLDER --fast-list _async=true -drive-pacer-burst 200 --drive-pacer-min-sleep 10ms --timeout 30m > /dev/null
      $(which sleep) 1
      $RCD vfs/refresh dir=$FOLDER --fast-list _async=true > /dev/null
done  
}

function rckill() {
source /system/mount/mount.env
log ">> kill it with fire <<"
$RCD mount/unmountall > /dev/null
folderunmount
}

function rcclean() {
source /system/mount/mount.env
log ">> run fs cache clear <<"
$RCD fscache/clear --fast-list _async=true > /dev/null
}

function rcstats() {
# NOTE LATER
source /system/mount/mount.env
log ">> get rclone stats <<"
$RCD core/stats
}

function drivecheck() {
   if [ "$(ls -1p /mnt/unionfs)" ] && [ "$(ls -1p /mnt/remotes)" ]; then rcclean && refreshVFS ; fi
}

function testrun() {
## force a start sleeping to fetch all options 
  rlog && sleep 5
## FINAL LOOP
while true; do
   source /system/mount/mount.env
   if [ "$(ls -1p /mnt/remotes)" ] && [ "$(ls -1p /mnt/unionfs)" ]; then
      log "${startuprcloneworks}" && sleep 360
   else
      rckill && rcmount && rcmergerfs && rcclean
   fi
   rlog && lang && checkban && sleep 360
done
}

#########################################
# Till here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
     ### DO NOT MAKE ANY CHANGES ###
##  IF YOU DON'T KNOW WHAT YOU'RE DOING ##
##########################################

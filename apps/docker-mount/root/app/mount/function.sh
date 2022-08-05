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

#########################################
# From here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
function log() {
   echo "[Mount] ${1}"
}

function checkban() {
if [[ `cat "${MLOG}" | wc -l` -gt 0 ]]; then
   tail -n 20 "${MLOG}" | grep --line-buffered 'downloadQuotaExceeded' | while read ;do
       if [ $? = 0 ]; then
          if [[ ! ${DISCORD_SEND} != "null" ]]; then
             discord
          else
             log "${startuphitlimit}"
          fi
          if [[ ${ARRAY} != 0 ]]; then
             rotate && log "${startuprotate}"
          fi
       fi
   done
fi
}

function rotate() {
[[ -f "/system/mount/.keys/lastkey" ]] && \
   $(which rm) -rf /system/mount/.keys/lastkey
[[ ! -d "/system/mount/.keys" ]] && \
   $(which mkdir) -p /system/mount/.keys/ && \
   $(which chown) -cR 1000:1000 /system/mount/.keys/ &>/dev/null
[[ -d "/system/mount/.keys" ]] && \
   $(which chown) -cR 1000:1000 /system/mount/.keys/ &>/dev/null
if [[ "${ARRAY}" -eq "0" ]]; then
   log " NO KEYS FOUND "
else
   JSONUSED=/system/mount/.keys/.usedkeys
   if [[ ! -f "${JSONUSED}" ]];then
      ls ${JSONDIR} | sed -e 's/\.json$//' | sort -u > ${JSONUSED}
   fi
   $(which cat) "${JSONUSED}" | head -n 1 | while IFS=$'|' read -ra KEY ; do
      IFS=$'\n'
      filter="$1"
      log "-->> We switch the ServiceKey to ${KEY} "
      mapfile -t mounts < <(eval rclone listremotes --config=${CONFIG} | grep "$filter" | sed -e 's/://g' | sed '/ADDITIONAL/d'  | sed '/downloads/d'  | sed '/crypt/d' | sed '/gdrive/d' | sed '/union/d' | sed '/remote/d')
      for remote in ${mounts[@]}; do
          $(which rclone) config update $remote service_account_file ${KEY}.json --config=${CONFIG}
          $(which rclone) config update $remote service_account_file_path $JSONDIR --config=${CONFIG}
      done
      $(which sed) -i 1d "${JSONUSED}" && break
   done
   NEXTKEY=$($(which cat) ${JSONUSED} | head -n 1)
   log "-->> Rotate to next ServiceKey done || MountKey is now ${NEXTKEY} "
   $(which cp) -r /app/rclone/rclone.conf /root/.config/rclone/ && sleep 5 || exit 1
   log "-->> Next possible ServiceKey is ${KEY} "
   if [[ -f "/tmp/rclone.sh" ]]; then
      rckill && rcclean && rcmount
   else
      rcmount
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

function envrenew() {
   diff -q "$ENVA" "$TMPENV"
   if [ $? -gt 0 ]; then
      rckill && rcmount && $(which cp) -r "$ENVA" "$TMPENV"
    else
      echo "no changes" &>/dev/null
   fi
}

function lang() {
   LANGUAGE=${LANGUAGE}
   currenttime=$(date +%H:%M)
   if [[ ! -d "/app/language" ]]; then
      $(which git) config --global --add safe.directory /app/language
      $(which git) -C /app clone --quiet https://github.com/dockserver/language.git
   fi
   if [[ "$currenttime" > "23:59" ]] || [[ "$currenttime" < "00:01" ]]; then
      if [[ -d "/app/language" ]]; then
         $(which git) config --global --add safe.directory /app/language
         $(which git) -C "${LFOLDER}/" stash --quiet
         $(which git) -C "${LFOLDER}/" pull --quiet
         $(which cd) "${LFOLDER}/"
         $(which git) stash clear
      fi
   fi
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
export ECLOG=/system/mount/logs/rclone-webui.log
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

### START WEBUI
$(which rclone) rcd \\
  --config=${CONFIG} \\
  --log-file=${MLOG} \\
  --log-level=${LOGLEVEL} \\
  --user-agent=${UAGENT} \\
  --cache-dir=${TMPRCLONE} \\
  --rc-files=/mnt \\
  --rc-no-auth \\
  --rc-allow-origin=* \\
  --rc-addr=0.0.0.0:8544 \\
  --rc-web-gui \\
  --rc-web-gui-force-update \\
  --rc-web-gui-no-open-browser \\
  --rc-web-fetch-url=https://api.github.com/repos/controlol/rclone-webui/releases/latest &

sleep 30
## SIMPLE START MOUNT
$(which rclone) rc mount/mount fs=remote: mountPoint=/mnt/remotes mountType=mount vfsOpt='{"PollInterval": 15000000000,"GID": 1000, "UID": 1000,"Umask": 0,"DirCacheTime": 172800000000000}' mountOpt='{"AllowOther": true}'
## SET OPTIONS_RCLONE over json
sleep 30
$(which rclone) rc options/set --json {'"main": {"DisableHTTP2": true, "MultiThreadStreams": 5, "TPSLimitBurst": 20, "TPSLimit": 20, "BufferSize": 3217899 }'}
$(which rclone) rc options/set --json {'"vfs": {"CacheMode": 3, "GID": '1000', "UID": '1000', "DirCacheTime": 172800000000000, "FastFingerprint": true, "ChunkSizeLimit": 3217899, "CacheMaxSize": 152777216000, "CacheMaxAge": 172800000000000, "ReadAhead": 67108864, "NoModTime": true, "NoChecksum": true, "WriteBack": 10000000000}'}
$(which rclone) rc options/set --json {'"mount": {"AllowNonEmpty":true, "AllowOther":true, "AsyncRead":true}'}

touch /tmp/rclone.running
EOF
echo $(date) > /tmp/rclone.running
###

## SET PERMISSIONS 
[[ -f "/tmp/rclone.sh" ]] && \
   $(which chmod) 755 /tmp/rclone.sh && \
   $(which bash) /tmp/rclone.sh

while true; do
  if [ "$(ls -1p /mnt/remotes)" ]; then
     break
  else 
     sleep 5
  fi
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
      $(which rclone) rc vfs/forget dir=$FOLDER --fast-list _async=true
      $(which sleep) 1
      $(which rclone) rc vfs/refresh dir=$FOLDER --fast-list _async=true
done  
}

function rckill() {
source /system/mount/mount.env
log ">> kill it with fire <<"
## GET NAME TO KILL ##
$(which rclone) rc mount/unmountall

folderunmount
}

function rcclean() {
source /system/mount/mount.env
log ">> run fs cache clear <<"
$(which rclone) rc fscache/clear --fast-list _async=true
}

function rcstats() {
# NOTE LATER
source /system/mount/mount.env
log ">> get rclone stats <<"
$(which rclone) rc core/stats
}

function drivecheck() {
   if [ "$(ls -1p /mnt/unionfs)" ] && [ "$(ls -1p /mnt/remotes)" ]; then
      rcclean && refreshVFS
   fi
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
   rlog && envrenew && lang && checkban && sleep 360
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

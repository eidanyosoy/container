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
source /system/mount/mount.env
#SETTINGS
ENDCONFIG=/app/rclone/rclone.conf
ENVA=/system/mount/mount.env
HEALTHCHECK=/mnt/unionfs/.healthcheck/test
TMPENV=/tmp/mount.env
TMPMERGER=/tmp/mergerfs.txt

#FOLDER
SUNION=/mnt/unionfs
SMOUNT=/app/mount
SREMOTES=/mnt/remotes
SDOWN=/mnt/downloads
JSONDIR=/system/mount/keys
USEDDIR=/system/mount/.keys
JSONUSED=/system/mount/.keys/usedkeys
LFOLDER=/app/language/mount
ARRAY=$($(which ls) -A "${JSONDIR}" | $(which wc) -l)

#LOG
LOGS=/system/mount/logs
RLOG=/system/mount/logs/rclone.log

#########################################
# From here on out, you probably don't  #
#   want to change anything unless you  #
#   know what you're doing.             #
#########################################
function log() {
   GRAY="\033[0;37m"
   BLUE="\033[0;34m"
   NC="\033[0m"
   $(which echo) -e "${GRAY}[$(date +'%Y/%m/%d %H:%M:%S')]${BLUE} [Mount]${NC} ${1}"
}

function notification() {
   source /system/mount/mount.env
   if [[ "${NOTIFYTYPE}" == "" ]]; then
     NOTIFYTYPE="info"
   fi
   if [[ "${NOTIFICATION_SERVERNAME}" == "null" ]]; then
     NOTIFICATION_NAME="Docker"
   else
     NOTIFICATION_NAME="${NOTIFICATION_SERVERNAME}"
   fi
   if [[ "${NOTIFICATION_URL}" != "null" ]]; then
      log "${MSG}" && apprise --notification-type="${NOTIFYTYPE}" --title="Mount - ${NOTIFICATION_NAME}" --body="${MSG}" "${NOTIFICATION_URL}/?format=markdown"
   else
      log "${MSG}"
   fi
}

function checkban() {
   CHECKBAN=$($(which tail) -n 25 "${RLOG}" | $(which grep) -qE "downloadQuotaExceeded" && echo true || echo false)
   if [[ "${CHECKBAN}" = "true" ]]; then
      MSG="${startuphitlimit}" && notification
      if [[ "${ARRAY}" -gt "0" ]]; then
         rotate
      fi
   fi
}

function rotate() {
   if [[ ! -d "${USEDDIR}" ]]; then $(which mkdir) -p "${USEDDIR}" && $(which chown) -hR abc:abc "${USEDDIR}"; fi
   if [[ -d "${USEDDIR}" ]]; then $(which chown) -hR abc:abc "${USEDDIR}"; fi
   if [[ "${ARRAY}" -lt "1" ]]; then
      log "-> No Keys found <-"
   else
      ARRAY=$($(which ls) -A "${JSONDIR}" | $(which wc) -l)
      if [[ ! -f "${JSONUSED}" ]]; then
         $(which ls) -A "${JSONDIR}" | $(which sort) -V > "${JSONUSED}"
      else
         ARRAYJSON=$($(which cat) "${JSONUSED}" | $(which wc) -l)
         $(which sed) -i '1h;1d;$G' "${JSONUSED}"
         if [[ "${ARRAY}" != "${ARRAYJSON}" ]]; then
            $(which rm) -rf "${JSONUSED}" && $(which ls) -A "${JSONDIR}" | $(which sort) -V > "${JSONUSED}"
         fi
      fi
      KEY=$($(which sed) -n 1p "${JSONUSED}")
      KEYNOTI=$($(which sed) -n 1p "${JSONUSED}" | $(which awk) -F '.' '{print $1}')
      log "-> We switch the Service 🔑 to "${KEYNOTI}" <-"
      mapfile -t MOUNTS < <($(which rclone) config dump --config="${ENDCONFIG}" | $(which jq) -r 'to_entries | (.[] | select(.value.team_drive)) | .key')
      for REMOTE in "${MOUNTS[@]}"; do
         $(which rclone) rc backend/command command=set fs="${REMOTE}": -o service_account_file="${JSONDIR}/${KEY}" -o service_account_path="${JSONDIR}" &>/dev/null
      done
      $(which sleep) 5
      $(which rclone) rc core/stats-reset &>/dev/null
      $(which logrotate) /etc/logrotate.conf &>/dev/null
      if [[ "$($(which ls) -1p ${SREMOTES})" ]] && [[ "$($(which ls) -1p ${SUNION})" ]]; then
         KEYNOTI=$($(which sed) -n 1p "${JSONUSED}" | $(which awk) -F '.' '{print $1}')
         MSG="-> Rotate to next Service 🔑 "${KEYNOTI}" done <-" && notification
      fi
      NEXTKEY=$($(which sed) -n 2p "${JSONUSED}" | $(which awk) -F '.' '{print $1}')
      log "-> Next Service 🔑 is "${NEXTKEY}" <-"
   fi
}

function envrenew() {
   $(which diff) -q "${ENVA}" "${TMPENV}" &>/dev/null
   if [[ "$?" -gt "0" ]]; then
      if [[ ! -f "${ENVA}" ]]; then
         MSG="${failednewchanges}" && notification
      else
         MSG="${startupnewchanges}" && notification
         rckill && rcmergerfskill && folderunmount && rcmount && rcmergerfs && $(which cp) -r "$ENVA" "$TMPENV"
         $(which sleep) 5 && testsuccessfull
      fi
   fi
}

function lang() {
   source /system/mount/mount.env
   startupmount=$($(which jq) ".startup.mount" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startuplogrotate=$($(which jq) ".startup.logrotate" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startuprclone=$($(which jq) ".startup.rclone" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupmergerfs=$($(which jq) ".startup.mergerfs" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupnzb=$($(which jq) ".startup.nzb" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startuphitlimit=$($(which jq) ".startup.hitlimit" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupnewchanges=$($(which jq) ".startup.newchanges" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupmountend=$($(which jq) ".startup.mountend" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startupmountworks=$($(which jq) ".startup.mountworks" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   startuprotate=$($(which jq) ".startup.rotate" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   killrclone=$($(which jq) ".kill.rclone" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   killmergerfs=$($(which jq) ".kill.mergerfs" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   killmount=$($(which jq) ".kill.mount" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   killunmountremote=$($(which jq) ".kill.unmountremote" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   killunmountremotes=$($(which jq) ".kill.unmountremotes" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   rclonevfs=$($(which jq) ".rclone.vfs" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   rcloneclean=$($(which jq) ".rclone.clean" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   rclonestats=$($(which jq) ".rclone.stats" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   rclonecache=$($(which jq) ".rclone.cache" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   rclonecacheend=$($(which jq) ".rclone.cacheend" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failedlog=$($(which jq) ".failed.log" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failedrclone=$($(which jq) ".failed.rclone" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failedmergerfs=$($(which jq) ".failed.mergerfs" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failednewchanges=$($(which jq) ".failed.newchanges" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failedunmountremote=$($(which jq) ".failed.unmountremote" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
   failedunmountremotes=$($(which jq) ".failed.unmountremotes" "${LFOLDER}/${LANGUAGE}.json" | $(which sed) 's/"\|,//g')
}

function folderunmount() {
   source /system/mount/mount.env
   $(which mountpoint) -q "${SUNION}" || $(which fusermount3) -uzq "${SUNION}" && log "${killunmountremote}" || log "${failedunmountremote}"
   mapfile -t fod < <($(which ls) -d ${SREMOTES}/* 2>/dev/null)
   for FOLDER in ${fod[@]}; do
      $(which mountpoint) -q "${FOLDER}" || $(which fusermount3) -uzq "${FOLDER}" && log "${killunmountremotes}" || log "${failedunmountremotes}"
   done
}


function rcmount() {
   source /system/mount/mount.env
   if [[ -f "/tmp/rclone.sh" ]]; then
      $(which rm) -f "/tmp/rclone.sh"
   fi

   #### VFS_CACHE_MAX_AGE to nanoseconds ####
   VFS_CACHE_MAX_AGE_CHECK=$($(which echo) "${VFS_CACHE_MAX_AGE:0-1}")

   if [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "s" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 1000000000 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "m" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 60000000000 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "h" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 3600000000000 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "d" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 86400000000000 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "w" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 604800016558522 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "M" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 2629800000000000 ))
   elif [[ "${VFS_CACHE_MAX_AGE_CHECK}" == "y" ]]; then
      VFS_CACHE_MAX_AGE_CHANGE=$($(which echo) "${VFS_CACHE_MAX_AGE::-1}")
      VFS_CACHE_MAX_AGE_NS=$(( ${VFS_CACHE_MAX_AGE_CHANGE} * 31557600000000000 ))
   else
      VFS_CACHE_MAX_AGE_NS="${VFS_CACHE_MAX_AGE}"
   fi

   #### VFS_DIR_CACHE_TIME to nanoseconds ####
   VFS_DIR_CACHE_TIME_CHECK=$($(which echo) "${VFS_DIR_CACHE_TIME:0-1}")

   if [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "s" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 1000000000 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "m" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 60000000000 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "h" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 3600000000000 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "d" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 86400000000000 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "w" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 604800016558522 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "M" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 2629800000000000 ))
   elif [[ "${VFS_DIR_CACHE_TIME_CHECK}" == "y" ]]; then
      VFS_DIR_CACHE_TIME_CHANGE=$($(which echo) "${VFS_DIR_CACHE_TIME::-1}")
      VFS_DIR_CACHE_TIME_NS=$(( ${VFS_DIR_CACHE_TIME_CHANGE} * 31557600000000000 ))
   else
      VFS_DIR_CACHE_TIME_NS="${VFS_DIR_CACHE_TIME}"
   fi

   #### SET PROXY IF AVAILABLE ####
   if [[ "${PROXY}" == "" ]]; then
      PROXY="null"
   fi
   if [[ "${PROXY}" != "null" ]]; then
      export no_proxy="localhost,127.0.0.0/8"
      export http_proxy="${PROXY}"
      export https_proxy="${PROXY}"
      export NO_PROXY="localhost,127.0.0.0/8"
      export HTTP_PROXY="${PROXY}"
      export HTTPS_PROXY="${PROXY}"
   fi

$(which cat) > "/tmp/rclone.sh" << EOF; $(echo)
#!/command/with-contenv bash
# shellcheck shell=bash
# auto generated

$(which fusermount3) -uzq "${SUNION}"
mapfile -t fod < <($(which ls) -d ${SREMOTES}/* 2>/dev/null)
for FOLDER in \${fod[@]}; do
   $(which fusermount3) -uzq "\${FOLDER}"
done

#### START RCLONE ####
$(which rclone) rcd \\
  --config="${ENDCONFIG}" \\
  --log-file="${RLOG}" \\
  --log-level="${LOG_LEVEL}" \\
  --ignore-errors \\
  --cache-dir="${TMPRCLONE}" \\
  --drive-use-trash="${DRIVETRASH}" \\
  --drive-server-side-across-configs \\
  --drive-acknowledge-abuse \\
  --rc-no-auth \\
  --rc-allow-origin=* \\
  --rc-addr=:5572 \\
  --rc-web-gui \\
  --rc-web-gui-force-update \\
  --rc-web-gui-no-open-browser &

$(which sleep) 10

#### SET OPTIONS FOR MOUNT ####
$(which rclone) rc options/set --json {'"main": { "TPSLimitBurst": ${TPSBURST}, "TPSLimit": ${TPSLIMIT}, "BufferSize": "${BUFFER_SIZE}", "UserAgent": "${UAGENT}", "UseMmap":true}'} &>/dev/null
$(which rclone) rc options/set --json {'"vfs": { "GID": '${PGID}', "UID": '${PUID}', "Umask": '${UMASK}', "CacheMode": 3, "CacheMaxSize": "${VFS_CACHE_MAX_SIZE}", "CacheMaxAge": ${VFS_CACHE_MAX_AGE_NS}, "CachePollInterval": 60000000000, "PollInterval": 30000000000, "ChunkSize": "${VFS_READ_CHUNK_SIZE}", "ChunkSizeLimit": "${VFS_READ_CHUNK_SIZE_LIMIT}", "DirCacheTime": ${VFS_DIR_CACHE_TIME_NS}, "FastFingerprint": true, "NoModTime": true}'} &>/dev/null
$(which rclone) rc options/set --json {'"mount": { "AllowNonEmpty": true, "AllowOther": true}'} &>/dev/null
$(which sleep) 5

#### START MOUNT ####
if [[ "${RUNION}" == "true" ]]; then
   $(which rclone) rc mount/mount fs=remote: mountPoint="${SREMOTES}" mountType=mount &>/dev/null
else
   mapfile -t mounts < <($(which rclone) config dump --config="${ENDCONFIG}" | $(which jq) -r 'to_entries | (.[] | select(.value)) | .key')
   for REMOTE in \${mounts[@]}; do
      CHECKCRYPT=\$($(which echo) "$(which rclone) config dump --config="${ENDCONFIG}" | $(which jq) -r 'to_entries | (.[] | select(.value.remote | index(\\"\${REMOTE}\\"))) | .key'" | bash -)
      if [[ "\${CHECKCRYPT}" == "" ]]; then
         if [[ ! -d "${SREMOTES}/\${REMOTE}" ]]; then $(which mkdir) -p "${SREMOTES}/\${REMOTE}" && $(which chown) -hR abc:abc "${SREMOTES}/\${REMOTE}" && $(which chmod) -R 775 "${SREMOTES}/\${REMOTE}" &>/dev/null; fi
         $(which rclone) rc mount/mount fs="\${REMOTE}:" mountPoint="${SREMOTES}/\${REMOTE}" mountType=mount &>/dev/null
      fi
   done
fi

EOF

   #### SET PERMISSIONS ####
   if [[ -f "/tmp/rclone.sh" ]]; then
      $(which chmod) 755 "/tmp/rclone.sh" &>/dev/null
      $(which bash) "/tmp/rclone.sh"
   fi

}

function rcmergerfs() {
   source /system/mount/mount.env
   if [[ "${RUNION}" == "true" ]]; then
      if [[ -d "${ADDITIONAL_MOUNT}" ]]; then
         UFSPATH="${SDOWN}=RW:${ADDITIONAL_MOUNT}=${ADDITIONAL_MOUNT_PERMISSION}:${SREMOTES}=NC"
      else
         UFSPATH="${SDOWN}=RW:${SREMOTES}=NC"
      fi
   else
      if [[ -f "${TMPMERGER}" ]]; then rm -rf "${TMPMERGER}"; fi
      mapfile -t mergerfs < <($(which ls) -d ${SREMOTES}/* 2>/dev/null)
      for REMOTE in ${mergerfs[@]}; do
         $(which echo) -n "${REMOTE}=NC:" >> "${TMPMERGER}"
      done
      $(which sed) -i 's/.$//' "${TMPMERGER}"
      TMPMERGERFILE=$($(which cat) "${TMPMERGER}")
      if [[ -d "${ADDITIONAL_MOUNT}" ]]; then
         UFSPATH="${SDOWN}=RW:${ADDITIONAL_MOUNT}=${ADDITIONAL_MOUNT_PERMISSION}:${TMPMERGERFILE}"
      else
         UFSPATH="${SDOWN}=RW:${TMPMERGERFILE}"
      fi
   fi

   MGFS="rw,use_ino,allow_other,statfs_ignore=nc,func.getattr=newest,category.action=all,category.create=ff,cache.files=auto-full,dropcacheonclose=true,fsname=mergerfs"
   #### TO RUN JUST ONCE ####
   if ! $(which pgrep) -x "mergerfs" > /dev/null; then
      $(which mergerfs) -o "${MGFS}" "${UFSPATH}" "${SUNION}" &>/dev/null
   fi
}

function rckill() {
   source /system/mount/mount.env
   log "${killrclone}"
   #### GET NAME TO KILL ####
   for KILL in `$(which pgrep) -x rclone`; do
       $(which kill) -9 "${KILL}"
   done
}

function rcmergerfskill() {
   source /system/mount/mount.env
   log "${killmergerfs}"
   #### GET NAME TO KILL ####
   for KILL in `$(which pgrep) -x mergerfs`; do
       $(which kill) -9 "${KILL}"
   done
}

function rcmountkill() {
   source /system/mount/mount.env
   log "${killmount}"
   $(which rclone) rc mount/unmountall &>/dev/null
}

function rcrefresh() {
   source /system/mount/mount.env
   $(which rclone) rc vfs/refresh recursive=true _async=true &>/dev/null
}

function rctest() {
   mapfile -t "MOUNTS" < <($(which rclone) rc mount/listmounts | jq -r '.[]' | $(which jq) -r 'to_entries | (.[] | select(.value)) | .value.Fs')
   for FS in ${MOUNTS[@]}; do
      $(which rclone) lsf "${FS}:/.healthcheck/test" &>/dev/null
	  if [[ "$?" -gt "0" ]]; then
	     $(which rclone) touch "${FS}:/.healthcheck/test" --config="${ENDCONFIG}" &>/dev/null
	  fi
   done
}

function rcstats() {
   source /system/mount/mount.env
   log "${rclonestats}"
   $(which rclone) rc core/stats
}

function nzbcleanup() {
   while true; do
      source /system/mount/mount.env
      DRIVEPERCENT=$($(which df) --output=pcent /mnt | $(which tr) -dc '0-9')
      if [[ "${NZBCLEANUP}" != "false" ]]; then
         if [[ ! "${DRIVEPERCENT}" -ge "${DRIVEUSEDPERCENT}" ]]; then
            $(which sleep) 120
         else
            $(which find) "${NZBBACKUPFOLDER}"/* -type d -mmin +"${NZBBACKUPTIME}" -exec rm -rf {} \; &>/dev/null
            $(which find) "${NZBDOWNLOADFOLDER}"/* -type f -mmin +"${NZBDOWNLOADTIME}" -exec rm -rf {} \; &>/dev/null
            $(which sleep) 120
         fi
      else
         $(which sleep) 120
      fi
   done
}

function testsuccessfull() {
   source /system/mount/mount.env
   $(which sleep) 10 && rctest
   if [[ -f "${HEALTHCHECK}" ]]; then
      MSG="${startupmountend}" && notification
      rcrefresh
   else
      rckill && rcmergerfskill && folderunmount && rcmount && rcmergerfs
   fi
}

function testrun() {
   #### FORCE START SLEEPING TO FETCH OPTIONS ####
   $(which sleep) 5
   #### FINAL LOOP ####
   while true; do
      source /system/mount/mount.env
      if [[ -f "${HEALTHCHECK}" ]]; then
         log "${startupmountworks}"
      else
         rckill && rcmergerfskill && folderunmount && rcmount && rcmergerfs
      fi
      envrenew && lang && checkban && $(which sleep) 360
   done
}

#### END OF FILE ####

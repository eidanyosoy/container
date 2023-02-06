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

#SETTINGS
ENVA=/config/restic/restic.env

function log() {
   GRAY="\033[0;37m"
   BLUE="\033[0;34m"
   NC="\033[0m"
   $(which echo) -e "${GRAY}[$($(which date) +'%Y/%m/%d %H:%M:%S')]${BLUE} [Restic]${NC} ${1}"
}

function notification() {
   source ${ENVA}
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
      log "${MSG}" && apprise --notification-type="${NOTIFYTYPE}" --title="Restic - ${NOTIFICATION_NAME}" --body="${MSG}" "${NOTIFICATION_URL}/?format=markdown"
   else
      log "${MSG}"
   fi
}

function resticsnapshots() {
   source ${ENVA}
   #### CHECK SNAPSHOTS ####
   $(which restic) snapshots --quiet --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf"
}

function resticforget() {
   source ${ENVA}
   #### DELETE OLD BACKUPS ####
   $(which restic) forget --quiet --tag "${RESTIC_TAG}" --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf" --keep-within-daily 14d --keep-within-weekly 1m --keep-within-monthly 1y --keep-within-yearly 2y --prune &>/dev/null
}

function resticrestore() {
   source ${ENVA}
   #### RESTORE SINGLE APP ####
   $(which restic) restore latest --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --target "/" --tag "${RESTIC_TAG}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf" --include "${RESTIC_FOLDER}/$@"
}

function resticrestore-full() {
   source ${ENVA}
   #### RESTORE FULL APPDATA ####
   $(which restic) restore latest --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --target "/" --tag "${RESTIC_TAG}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf"
}

function resticmount() {
   source ${ENVA}
   #### MOUNT BACKUP ####
   $(which mkdir) -p /mnt/restic
   $(which restic) mount --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --tag "${RESTIC_TAG}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf" /mnt/restic
}

function resticbackup() {
   source ${ENVA}
   #### START BACKUP ####
   if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]]; then
      log "-> Backup for ${RESTIC_TAG} is started <-"
   fi
   $(which restic) backup --quiet --tag "${RESTIC_TAG}" --repo "${RESTIC_REPOSITORY}" --password-command "$(which echo) ${RESTIC_PASSWORD}" --host "${RESTIC_HOST}" --cache-dir "${RESTIC_CACHE_DIR}" --cleanup-cache --pack-size "${RESTIC_PACK_SIZE}" --option rclone.args="serve restic --stdio --checkers=16 --drive-chunk-size=32M --drive-use-trash=false --fast-list --config=/config/rclone/rclone.conf" "${RESTIC_FOLDER}" &>/dev/null
   if [[ "$?" == "0" ]]; then
      if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]]; then
         MSG="-> ✅ Backup successful for ${RESTIC_TAG} <-" && notification
      fi
   elif [[ "$?" == "1" ]]; then
      if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]] || [[ ${NOTIFICATION_LEVEL} == "ERROR" ]]; then
         MSG="-> ❌ Backup failed for ${RESTIC_TAG} <-" && notification
      fi
   elif [[ "$?" == "3" ]]; then
      if [[ "${NOTIFICATION_LEVEL}" == "ALL" ]] || [[ ${NOTIFICATION_LEVEL} == "ERROR" ]]; then
         MSG="-> ❌ There are some problems with the ${RESTIC_TAG} backup <-" && notification
      fi
   fi
   #### DELETE OLD BACKUPS ####
   resticforget
}

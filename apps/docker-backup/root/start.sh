#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2021, dockserver
# All rights reserved
# Idee from scorb/docker-volume-backup
# customizable: yes
# fork allowing: yes
# modification allowed: yes
######
#FUNCTIONS START
OPTIONSTAR="--warning=no-file-changed \
  --ignore-failed-read \
  --absolute-names \
  --warning=no-file-removed \
  --exclude-from=/backup_excludes \
  --use-compress-program=pigz"
OPTIONSTARPW="--warning=no-file-changed \
  --ignore-failed-read \
  --absolute-names \
  --warning=no-file-removed \
  --exclude-from=/backup_excludes"
#FUNCTIONS END
usage() {
  echo ""
  echo "Usage: <backup|restore|check> <appname> || <password>"
  echo ""
  echo "          Unencrypted tar.gz"
  echo "Example  unencrypted (backup): <backup> <appname> <storage>"
  echo "Example unencrypted (restore): <restore> <appname> <storage>"
  echo "Example   unencrypted (check): <check> <appname> <storage>"
  echo ""
  echo "          Encrypted tar.gz.enc"
  echo "Example    encrypted (backup): <backup> <appname> <storage> <password>"
  echo "Example   encrypted (restore): <restore> <appname> <storage> <password>"
  echo "Example     encrypted (check): <check> <appname> <storage> <password>"
  echo ""
  exit
}
## backup specific app
backup() {
STARTTIME=$(date +%s)
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
ARCHIVETAR=${ARCHIVE}.tar.gz
DESTINATION="/mnt/downloads/appbackups"
STORAGE=${STORAGE}
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
apk --quiet --no-cache --no-progress update && \
apk --quiet --no-cache --no-progress upgrade
inst="rsync bc pigz tar pv"
for i in ${inst};do
    apk --quiet --no-cache --no-progress add $i && echo "depends install of $i"
done
echo "Start tar for ${ARCHIVETAR}"
cd /${OPERATION}/${ARCHIVE} && tar ${OPTIONSTAR} -C ${ARCHIVE} -pcf ${ARCHIVETAR} ./ 
echo "Finished tar for ${ARCHIVE}"
if [[ ! -d ${DESTINATION}/${STORAGE} ]];then $(command -v mkdir) -p ${DESTINATION}/${STORAGE};fi
   $(command -v rsync) -aqhv --remove-source-files /${OPERATION}/${ARCHIVE}/${ARCHIVETAR} ${DESTINATION}/${STORAGE}/${ARCHIVETAR}
   $(command -v chown) -hR 1000:1000 ${DESTINATION}/${STORAGE}/${ARCHIVETAR}
echo "Finished rsync for ${ARCHIVETAR} to ${DESTINATION}/${STORAGE}"
ENDTIME=$(date +%s)
TIME="$((count=${ENDTIME}-${STARTTIME}))"
duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
echo "${OPERATION} used ${duration} for ${OPERATION} ${ARCHIVE} ${STORAGE}"
exit
}
backuppw() {
STARTTIME=$(date +%s)
## parser
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
ARCHIVETAR=${ARCHIVE}.tar.gz
STORAGE=${STORAGE}
DESTINATION="/mnt/downloads/appbackups"
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
apk --quiet --no-cache --no-progress update
apk --quiet --no-cache --no-progress upgrade
inst="rsync bc pigz tar"
for i in ${inst};do
    apk --quiet --no-cache --no-progress add $i && echo "depends install of $i"
done
echo "Start protect-tar for ${PASSWORDTAR}"
cd /${OPERATION}/${ARCHIVE} && tar ${OPTIONSTARPW} -cz ${ARCHIVE}/ | openssl enc -aes-256-cbc -e -pass pass:${PASSWORD} > ${ARCHIVEROOT}/${PASSWORDTAR}
echo "Finished protect-tar for ${PASSWORDTAR}"
if [[ ! -d ${DESTINATION}/${STORAGE} ]];then $(command -v mkdir) -p ${DESTINATION}/${STORAGE};fi
   $(command -v rsync) -aqhv --remove-source-files /${OPERATION}/${ARCHIVE}/${PASSWORDTAR} ${DESTINATION}/${STORAGE}/${PASSWORDTAR}
   $(command -v chown) -hR 1000:1000 ${DESTINATION}/${STORAGE}/${PASSWORDTAR}
echo "Finished rsync for ${PASSWORDTAR} to ${DESTINATION}/${STORAGE}"
ENDTIME=$(date +%s)
TIME="$((count=${ENDTIME}-${STARTTIME}))"
duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
echo "${OPERATION} used ${duration} for ${OPERATION} ${PASSWORDTAR}"
exit
}
## restore specific app
restore() {
STARTTIME=$(date +%s)
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
ARCHIVETAR=${ARCHIVE}.tar.gz
STORAGE=${STORAGE}
DESTINATION="/mnt/unionfs/appbackups"
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
if [[ ! -f ${DESTINATION}/${STORAGE}/${ARCHIVETAR} ]];then noarchivefound;fi
apk --quiet --no-cache --no-progress update
apk --quiet --no-cache --no-progress upgrade
inst="bc pigz tar"
for i in ${inst};do
    apk --quiet --no-cache --no-progress add $i && echo "depends install of $i"
done
if [[ ! -d /${OPERATION}/${ARCHIVE} ]];then $(command -v mkdir) -p /${OPERATION}/${ARCHIVE};fi
echo "Start untar for ${ARCHIVETAR} on /${OPERATION}/${ARCHIVE}"
   unpigz -dcqp 4 ${DESTINATION}/${STORAGE}/${ARCHIVETAR} | tar pxf - -C /${OPERATION}/${ARCHIVE}
echo "Finished untar for ${ARCHIVETAR}"
ENDTIME=$(date +%s)
TIME="$((count=${ENDTIME}-${STARTTIME}))"
duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
echo "${OPERATION} used ${duration} for ${OPERATION} ${ARCHIVE} ${STORAGE}"
exit
}
restorepw() {
STARTTIME=$(date +%s)
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
STORAGE=${STORAGE}
DESTINATION="/mnt/unionfs/appbackups"
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
if [[ ! -f ${DESTINATION}/${STORAGE}/${ARCHIVETAR} ]];then noarchivefoundpw;fi
apk --quiet --no-cache --no-progress update
apk --quiet --no-cache --no-progress upgrade
inst="bc pigz tar"
for i in ${inst};do
    apk --quiet --no-cache --no-progress add $i && echo "depends install of $i"
done
if [[ ! -d /${OPERATION}/${ARCHIVE} ]];then $(command -v mkdir) -p ${ARCHIVEROOT};fi
echo "Start protect-untar for ${PASSWORDTAR} on ${ARCHIVEROOT}"
   openssl aes-256-cbc -pass pass:${PASSWORD} -d -in ${PASSWORDTAR} | unpigz -dcqp 4 ${DESTINATION}/${STORAGE}/${ARCHIVETAR} | tar ospxf - -C /${OPERATION}/${ARCHIV}
echo "Finished protect-untar for ${PASSWORDTAR}"
ENDTIME=$(date +%s)
TIME="$((count=${ENDTIME}-${STARTTIME}))"
duration="$(($TIME / 60)) minutes and $(($TIME % 60)) seconds elapsed."
echo "${OPERATION} used ${duration} for ${OPERATION} ${ARCHIVE} ${STORAGE}"
exit
}
noarchivefoundpw() {
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
ARCHIVETAR=${ARCHIVE}.tar.gz
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
STORAGE=${STORAGE}
DESTINATION="/mnt/unionfs/appbackups"
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERROR
    Sorry , We could not find ${PASSWORDTAR} on ${DESTINATION}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
sleep 10 && exit
}
noarchivefound() {
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
ARCHIVETAR=${ARCHIVE}.tar.gz
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
STORAGE=${STORAGE}
DESTINATION="/mnt/unionfs/appbackups"
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERROR
    Sorry , We could not find ${ARCHIVETAR} on ${DESTINATION}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
sleep 10 && exit
}
## check specific app of existing
check() {
## parser
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
ARCHIVETAR=${ARCHIVE}.tar.gz
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
STORAGE=${STORAGE}
DESTINATION="/mnt/unionfs/appbackups"
## start ##
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
if [[ -f ${DESTINATION}/${STORAGE}/${ARCHIVETAR} ]];then
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    👍
    We found ${ARCHIVETAR} on ${DESTINATION}/${STORAGE}
    You can restore or create a new backup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
else
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERROR
    Sorry , We could not find ${ARCHIVETAR} on ${DESTINATION}/${STORAGE}
    You need to create a backup before you can restore it.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
sleep 10 && exit
fi
}
checkpw() {
## parser
OPERATION=${OPERATION}
ARCHIVE=${ARCHIVE}
PASSWORD=${PASSWORD}
ARCHIVETAR=${ARCHIVE}.tar.gz
PASSWORDTAR=${ARCHIVE}.tar.gz.enc
DESTINATION="/mnt/unionfs/appbackups"
echo "show ${OPERATION} command = ${OPERATION} ${ARCHIVE} ${STORAGE}"
if [[ -f ${DESTINATION}/${STORAGE}/${PASSWORDTAR} ]];then
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    👍
    We found ${ARCHIVETAR} on ${DESTINATION}/${STORAGE}
    You can restore or create a new backup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
else
printf "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERROR
    Sorry , We could not find ${ARCHIVETAR} on ${DESTINATION}/${STORAGE}
    You need to create a backup before you can restore it.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
sleep 10 && exit
fi
}
# CHECK ARE 2 ARGUMENTES #
if [[ $# -lt 3 ]];then usage;fi
if [[ $# -gt 4 ]];then usage;fi 
# ARGUMENTES #
OPERATION=$1
ARCHIVE=$2
STORAGE=$3
PASSWORD=$4
# RUN PROTECTION #
if [[ $# -eq 4 ]];then
case "$OPERATION" in
 "backup" ) backuppw ;;
 "check" ) checkpw ;;
 "restore" ) restorepw ;;
esac
fi
# RUN NO-PROTECTION #
if [[ $# -eq 3 ]];then
case "$OPERATION" in
 "backup" ) backup ;;
 "check" ) check ;;
 "restore" ) restore ;;
esac
fi
#"

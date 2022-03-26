#!/usr/bin/with-contenv bash
#shellcheck shell=bash
####################################
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
# shellcheck disable=SC2006
   source /system/rclone/.env

   if [[ ${DRIVE} == "gdrive" ]]; then
      source /system/rclone/.env
      NAME=${NAME}
      CLIENT_ID_FROM_GOOGLE=${CLIENT_ID_FROM_GOOGLE}
      CLIENT_SECRET_FROM_GOOGLE=${CLIENT_SECRET_FROM_GOOGLE}
      ACCESSTOKEN=$(cat /system/rclone/.token | grep 'access_token' | awk '{print $2}')
      REFRESHTOKEN=$(cat /system/rclone/.token | grep 'refresh_token' | awk '{print $2}')
      source /system/rclone/.token
      rcdate=$(date +'%Y-%m-%d')
      rctime=$(date +"%H:%M:%S" --date="$givenDate 60 minutes")
      rczone=$(date +"%:z")
      final=$(echo "${rcdate}T${rctime}${rczone}")
      #export final=${final}
      echo -e "\n
#DockServer Added Drive #\n
[${NAME}]
type = drive
client_id = ${CLIENT_ID_FROM_GOOGLE}
client_secret = ${CLIENT_SECRET_FROM_GOOGLE}
server_side_across_configs = true
scope = drive
token = {\"access_token\":${ACCESSTOKEN}\"token_type\":\"Bearer\",\"refresh_token\":${REFRESHTOKEN}\"expiry\":\"${final}\"}" >>/system/rclone/rclone.conf
      echo "" >>/system/rclone/rclone.conf
      sleep 5 && exit
   fi

   if [[ ${DRIVE} == "gcrypt" ]]; then
      source /system/rclone/.env
      DRIVE=${DRIVE}
      NAME=${NAME}
      CLIENT_ID_FROM_GOOGLE=${CLIENT_ID_FROM_GOOGLE}
      CLIENT_SECRET_FROM_GOOGLE=${CLIENT_SECRET_FROM_GOOGLE}
      PASSWORD=${PASSWORD}
      SALT=${SALT}
      ENC_PASSWORD=$(rclone obscure ${PASSWORD} | tail -n1)
      ENC_SALT=$(rclone obscure ${SALT} | tail -n1)
      ACCESSTOKEN=$(cat /system/rclone/.token | grep 'access_token' | awk '{print $2}')
      REFRESHTOKEN=$(cat /system/rclone/.token | grep 'refresh_token' | awk '{print $2}')
      source /system/rclone/.token
      rcdate=$(date +'%Y-%m-%d')
      rctime=$(date +"%H:%M:%S" --date="$givenDate 60 minutes")
      rczone=$(date +"%:z")
      final=$(echo "${rcdate}T${rctime}${rczone}")

      echo -e "\n
#DockServer Added Drive #\n
[${NAME}]
type = drive
client_id = ${CLIENT_ID_FROM_GOOGLE}
client_secret = ${CLIENT_SECRET_FROM_GOOGLE}
server_side_across_configs = true
scope = drive
token = {\"access_token\":${ACCESSTOKEN}\"token_type\":\"Bearer\",\"refresh_token\":${REFRESHTOKEN}\"expiry\":\"${final}\"}
\n
[gcrypt-${NAME}]
type = crypt
remote = ${NAME}:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = ${ENC_PASSWORD}
password2 = ${ENC_SALT}" >>/system/rclone/rclone.conf
      echo "" >>/system/rclone/rclone.conf
      rclone mkdir --config=/system/rclone/rclone.conf ${NAME}:/encrypt
      sleep 5 && exit
   fi

   if [[ ${DRIVE} == "tdrive" ]]; then
      source /system/rclone/.env
      DRIVE=${DRIVE}
      NAME=${NAME}
      CLIENT_ID_FROM_GOOGLE=${CLIENT_ID_FROM_GOOGLE}
      CLIENT_SECRET_FROM_GOOGLE=${CLIENT_SECRET_FROM_GOOGLE}
      TDRIVE_ID=${TDRIVE_ID}
      ACCESSTOKEN=$(cat /system/rclone/.token | grep 'access_token' | awk '{print $2}')
      REFRESHTOKEN=$(cat /system/rclone/.token | grep 'refresh_token' | awk '{print $2}')
      source /system/rclone/.token
      rcdate=$(date +'%Y-%m-%d')
      rctime=$(date +"%H:%M:%S" --date="$givenDate 60 minutes")
      rczone=$(date +"%:z")
      final=$(echo "${rcdate}T${rctime}${rczone}")

      echo -e "\n 
#DockServer Added Drive #\n
[${NAME}]
type = drive
client_id = ${CLIENT_ID_FROM_GOOGLE}
client_secret = ${CLIENT_SECRET_FROM_GOOGLE}
server_side_across_configs = true
scope = drive
token = {\"access_token\":${ACCESSTOKEN}\"token_type\":\"Bearer\",\"refresh_token\":${REFRESHTOKEN}\"expiry\":\"${final}\"}
team_drive = ${TDRIVE_ID}" >>/system/rclone/rclone.conf
      echo "" >>/system/rclone/rclone.conf
      sleep 5 && exit
   fi

   if [[ ${DRIVE} == "tcrypt" ]]; then
      source /system/rclone/.env
      DRIVE=${DRIVE}
      NAME=${NAME}
      CLIENT_ID_FROM_GOOGLE=${CLIENT_ID_FROM_GOOGLE}
      CLIENT_SECRET_FROM_GOOGLE=${CLIENT_SECRET_FROM_GOOGLE}
      TDRIVE_ID=${TDRIVE_ID}
      #encryted passwords
      PASSWORD=${PASSWORD}
      SALT=${SALT}
      ENC_PASSWORD=$(rclone obscure ${PASSWORD} | tail -n1)
      ENC_SALT=$(rclone obscure ${SALT} | tail -n1)
      ACCESSTOKEN=$(cat /system/rclone/.token | grep 'access_token' | awk '{print $2}')
      REFRESHTOKEN=$(cat /system/rclone/.token | grep 'refresh_token' | awk '{print $2}')
      source /system/rclone/.token
      rcdate=$(date +'%Y-%m-%d')
      rctime=$(date +"%H:%M:%S" --date="$givenDate 60 minutes")
      rczone=$(date +"%:z")
      final=$(echo "${rcdate}T${rctime}${rczone}")

      echo -e "\n 
#DockServer Added Drive #\n
[${NAME}]
type = drive
client_id = ${CLIENT_ID_FROM_GOOGLE}
client_secret = ${CLIENT_SECRET_FROM_GOOGLE}
server_side_across_configs = true
scope = drive
token = {\"access_token\":${ACCESSTOKEN}\"token_type\":\"Bearer\",\"refresh_token\":${REFRESHTOKEN}\"expiry\":\"${final}\"}
team_drive = ${TDRIVE_ID}
\n
[tcrypt-${NAME}]
type = crypt
remote = ${NAME}:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = ${ENC_PASSWORD}
password2 = ${ENC_SALT}" >>/system/rclone/rclone.conf
      echo "" >>/system/rclone/rclone.conf
      rclone mkdir --config=/system/rclone/rclone.conf ${NAME}:/encrypt
      sleep 5 && exit
   fi
#EOF

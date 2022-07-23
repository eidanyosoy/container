#!/usr/bin/with-contenv bash
# shellcheck shell=bash
######################################################
# Copyright (c) 2022, dockserver.io                  #
######################################################
# All rights reserved.                               #
# started from Zero                                  #
# Docker owned from MrDoob                           #
# some codeparts are copyed from sagen from 88lex    #
# sagen is under MIT License                         #
# Copyright (c) 2019 88lex                           #
#                                                    #
# CREDITS: The scripts and methods are based on      #
# ideas/code/tools from ncw, max, sk, rxwatcher,     #
# l3uddz, zenjabba, dashlt, mc2squared, storm,       #
# physk , plexguide and all missed once              #
######################################################
#### INSIDE THE DOCKER
exportorg() {
setorg=$(gcloud organizations list --format="value(ID)")
export ORGANIZATIONID=$setorg
sleep $CYCLEDELAY
}

create_projects() {
while
  : ${start=$i}
  gcloud projects create $PROJECT$i --name=$PROJECT$i --organization=$ORGANIZATIONID && export PROJECT=$PROJECT$i && break
  (( ++i < 50 ))
do :; done
sleep $CYCLEDELAY
}

enable_apis() {
    gcloud config set project $PROJECT
    gcloud services enable drive.googleapis.com sheets.googleapis.com \
        admin.googleapis.com cloudresourcemanager.googleapis.com servicemanagement.googleapis.com
sleep $CYCLEDELAY
}

create_gdsas() {
gcloud config set project $PROJECT
let LAST_SA_NUM=$COUNT+$NUMGDSAS-1
   for name in $(seq $COUNT $LAST_SA_NUM); do
        PROGNAME="$SANAME""$name"
            gcloud iam service-accounts create $PROGNAME --display-name=$PROGNAME
        sleep $CYCLEDELAY
    done
sleep $CYCLEDELAY
SA_COUNT=`gcloud iam service-accounts list --format="value(EMAIL)" | sort | wc -l`
let COUNT=$COUNT+$NUMGDSAS
}

create_keys() {
    gcloud config set project $PROJECT
TOTAL_JSONS_BEF=`ls $KEYSDONE | grep "GDSA" | wc -l`
let LAST_SA_NUM=$COUNT+$NUMGDSAS-1
for name in $(seq $COUNT $LAST_SA_NUM); do
    PROGNAME="$SANAME""$name"
      gcloud iam service-accounts keys create $KEYSDONE/GDSA$name --iam-account=$PROGNAME@$PROJECT.iam.gserviceaccount.com
    echo "$PROGNAME@$PROJECT.iam.gserviceaccount.com" | tee -a /system/servicekeys/members.csv
    sleep $CYCLEDELAY
done
MEMBER_COUNT=`cat /system/servicekeys/members.csv | grep "gservice" | wc -l`
TOTAL_JSONS_NOW=`ls $KEYSDONE | grep "GDSA" | wc -l`
let TOTAL_JSONS_MADE=$TOTAL_JSONS_NOW-$TOTAL_JSONS_BEF
let COUNT=$COUNT+$NUMGDSAS
}

create_config() {
TOTAL_JSONS_BEF=`ls $KEYSDONE | grep "GDSA" | wc -l`
for build in $(seq $COUNT $TOTAL_JSONS_BEF); do
tee >>/system/servicekeys/rclonegdsa.conf  <<-"
[GDSA${build}]
type = drive
scope = drive
service_account_file = /system/servicekeys/keys/GDSA${build}
team_drive = ${TEAMDRIVEID}

"
if [[ ${ENCRYPT} == "true" || ${ENCRYPT} == "TRUE" ]]; then
   PASSWORD=${PASSWORD}
   SALT=${SALT}
tee >>/system/servicekeys/rclonegdsa.conf <<-"
[GDSA${build}C]
type = crypt
remote = GDSA${build}:/encrypt
filename_encryption = standard
directory_name_encryption = true
password = $PASSWORD
password2 = $SALT

"
fi
done
}

makecsv() {
  gcloud iam service-accounts list --project ${PROJECT} --format="value(email)" | sort > /system/servicekeys/members.csv
}

main() {
for function in exportorg create_projects enable_apis create_gdsas create_keys create_config makecsv;do
    COUNT=$FIRSTGDSA
    for project_num in $(seq $PROJECTNUM $LASTPROJECTNUM); do
        eval $function 
        sleep $SECTION_DELAY
    done
done
$(which rm) -rf /system/servicekeys/.env
}

######################################################################################
#FUNCTIONS
KEYSGEN=/system/servicekeys
KEYSDONE=/system/servicekeys/keys
if [[ -d ${KEYSDONE} ]];then $(which rm) -rf ${KEYSDONE};fi
if [[ ! -d ${KEYSGEN} ]];then $(which mkdir) -p ${KEYSGEN};fi
if [[ ! -d ${KEYSDONE} ]];then $(which mkdir) -p ${KEYSDONE};fi
if [[ -f "/system/servicekeys/members.csv" ]];then $(which rm) -rf /system/servicekeys/members.csv;fi
if [[ -f "/system/servicekeys/rclonegdsa.conf" ]];then $(which rm) -rf /system/servicekeys/rclonegdsa.conf;fi


if [[ -f "/system/servicekeys/.env" ]]; then 
   $(which rm) -rf "/system/servicekeys/.env" 
fi

## READ FROM EXPORTED ENVS
CYCLEDELAY=0.1s
SANAME=${SANAME}
FIRSTGDSA=1
LASTPROJECTNUM=1
SECTION_DELAY=2

#### USER VALUES ####
export NUMGDSAS=${NUMGDSAS}
export PROGNAME=${PROGNAME}
export ACCOUNT=${ACCOUNT}
export PROJECT=${PROJECT}
export TEAMDRIVEID=${TEAMDRIVEID}

## ENCRYPTED
export ENCRYPT=${ENCRYPT}
export PASSWORD=${PASSWORD}
export SALT=${SALT}

main

## TO RUN IT 
## EASIER IS NOT POSSIBLE 
##export alias gdsagen='docker run -it -v /opt/appdata/system/servicekeys/:/system/servicekeys/ ghcr.io/dockserver/docker-gdsa:latest /bin/bash /gdsastart.sh'
##source ~/.bashrc

#/E_o_F\#

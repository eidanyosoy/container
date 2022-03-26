#!/usr/bin/with-contenv bash
# shellcheck shell=bash
######################################################
# Copyright (c) 2021, MrDoob                         #
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
# shellcheck disable=SC2086
# shellcheck disable=SC2046

PROJECTRANDOM=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c16)

source $KEYS_DIR/.env
export KEYS_DIR=/system/mount/keys
export ACCOUNT=${ACCOUNT}
export GROUP_NAME=${GROUPNAME}
export PROJECT_BASE_NAME=${PROJECTRANDOM}
export FIRST_PROJECT_NUM=1
export LAST_PROJECT_NUM=5
export SA_EMAIL_BASE_NAME=mount
export FIRST_SA_NUM=01
export NUM_SAS_PER_PROJECT=100
export CYCLE_DELAY=0.5s
export SECTION_DELAY=5s
###################

exportorg() {
    set -x
    setorg=$(gcloud organizations list --format="value(ID)")
    export ORGANIZATIONID=$setorg
    set +x
    sleep $CYCLEDELAY
}

create_projects() {
    PROJECT="$PROJECT_BASE_NAME$project_num"
    echo -e "Creating project = $PROJECT"
    set -x
    gcloud projects create $PROJECT --name=$PROJECT --organization=$ORGANIZATION_ID
    export ORGANIZATION_ID=$ORGANIZATION_ID
    export PROJECT=$PROJECT
    set +x
    sleep $CYCLE_DELAY
}

enable_apis() {
    PROJECT="$PROJECT_BASE_NAME$project_num"
    echo -e "Enabling apis for project = $PROJECT"
    set -x
    gcloud config set project $PROJECT
    gcloud services enable drive.googleapis.com sheets.googleapis.com \
    admin.googleapis.com cloudresourcemanager.googleapis.com servicemanagement.googleapis.com
    set +x
    sleep $CYCLE_DELAY
}

create_sas() {
    PROJECT="$PROJECT_BASE_NAME$project_num"
    set -x
    gcloud config set project $PROJECT
    set +x
    echo -e "Create service accounts for project = $PROJECT"
    let LAST_SA_NUM=$COUNT+$NUM_SAS_PER_PROJECT-1
    for name in $(seq $COUNT $LAST_SA_NUM); do
        saname="$SA_EMAIL_BASE_NAME""$name"
        echo -e "Creating service account number $name in project = $PROJECT ==> $saname@$PROJECT"
        set -x
        gcloud iam service-accounts create $saname --display-name=$saname
        set +x
        sleep $CYCLE_DELAY
    done
    sleep $SECTION_DELAY
    SA_COUNT=$(gcloud iam service-accounts list --format="value(EMAIL)" | sort | wc -l)
    echo -e "Total number of service accounts in project $PROJECT = $SA_COUNT"
    let COUNT=$COUNT+$NUM_SAS_PER_PROJECT
}

create_keys() {
    PROJECT="$PROJECT_BASE_NAME$project_num"
    set -x
    gcloud config set project $PROJECT
    set +x
    echo -e "create json keys for $PROJECT"
    TOTAL_JSONS_BEF=$(ls -l $KEYS_DIR | egrep -c '*.json')
    let LAST_SA_NUM=$COUNT+$NUM_SAS_PER_PROJECT-1
    for name in $(seq $COUNT $LAST_SA_NUM); do
        saname="$SA_EMAIL_BASE_NAME""$name"
        echo -e "Creating json key $name.json in project = $PROJECT for service account = $saname@$PROJECT"
        set -x
        gcloud iam service-accounts keys create $KEYS_DIR/GDSA$name.json --iam-account=$saname@$PROJECT.iam.gserviceaccount.com
        set +x
        gcloud iam service-accounts add-iam-policy-binding $saname@$PROJECT.iam.gserviceaccount.com --member='serviceAccount:group:$GROUP_NAME' --role='roles/editor'
        echo "$GROUP_NAME,$saname@$PROJECT.iam.gserviceaccount.com,USER,MEMBER" | tee -a $KEYS_DIR/members.csv $KEYS_DIR/allmembers.csv
        sleep $CYCLE_DELAY
    done
    MEMBER_COUNT=$(cat $KEYS_DIR/members.csv | grep "gservice" | wc -l)
    echo -e "\nNumber of service accounts in members.csv = $MEMBER_COUNT"
    TOTAL_JSONS_NOW=$(ls -l $KEYS_DIR | egrep -c '*.json')
    let TOTAL_JSONS_MADE=$TOTAL_JSONS_NOW-$TOTAL_JSONS_BEF
    echo -e "Total keys created for project $PROJECT = $TOTAL_JSONS_MADE"
    let COUNT=$COUNT+$NUM_SAS_PER_PROJECT
}

main() {
    if [[ ! -d $KEYS_DIR ]]; then mkdir -p $KEYS_DIR; fi
    [ -f $KEYS_DIR/members.csv ] && cat $KEYS_DIR/members.csv >>$KEYS_DIR/allmembers.csv && \
    sort -uo $KEYS_DIR/allmembers.csv $KEYS_DIR/allmembers.csv
    echo "Group Email [Required],Member Email,Member Type,Member Role" >$KEYS_DIR/members.csv
    TOTAL_JSONS_START=$(ls -l $KEYS_DIR | egrep -c '*.json')
    echo -e "\nTotal keys before running Key-Gen = $TOTAL_JSONS_START"
    for function in exportorg create_projects enable_apis create_sas create_keys; do
        COUNT=$FIRST_SA_NUM
        for project_num in $(seq $FIRST_PROJECT_NUM $LAST_PROJECT_NUM); do
            eval $function && sleep $SECTION_DELAY
        done
    done
    TOTAL_JSONS_END=$(ls -l $KEYS_DIR | egrep -c '*.json')
    echo -e "\n\nTotal keys BEFORE running key-gen    = $TOTAL_JSONS_START"
    echo -e "Total keys AFTER running key-gen         = $TOTAL_JSONS_END"
    let TOTAL_JSONS_MADE=$TOTAL_JSONS_END-$TOTAL_JSONS_START
    echo -e "Total Keys CREATED                       = $TOTAL_JSONS_MADE"
    rm -rf /system/servicekeys/.env
}
######################################################################################
#FUNCTIONS

### needs to be in ENV !!
# ACCOUNT=${ACCOUNT} = USER Identity
# GROUP_NAME=${GROUPNAME}  = Google Group ( must exist before!)
# PROJECT_BASE_NAME=${PROJECT} = is set to random unique
###

if [[ ! -d $KEYS_DIR ]]; then mkdir -p $KEYS_DIR; fi
if [[ -f "$KEYS_DIR/allmembers.csv" ]]; then $(command -v rm) -rf $KEYS_DIR/allmembers.csv; fi
if [[ -f "$KEYS_DIR/members.csv" ]]; then $(command -v rm) -rf $KEYS_DIR/members.csv; fi

   find $KEYS_DIR/ -type f -iname "*.json" -exec rm -rf \{\} \;

if [[ -f "$KEYS_DIR/.env" ]]; then main; fi

#E-O-F#

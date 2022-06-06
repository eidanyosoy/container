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

cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

   install=(python3 py3-crcmod py3-openssl bash libc6-compat openssh-client git gnupg bc curl wget openssl ca-certificates)

   log "**** update system packages ****" && \
   apk --quiet --no-cache --no-progress update && \
   apk --quiet --no-cache --no-progress upgrade && \
   log "**** install build packages ****" && \
   apk add --quiet --no-cache --no-progress --virtual=build-dependencies ${install[@]}
   unset install

MOUNT=/system/mount/keys/.env
GDSA=/system/servicekeys/.env

shfile=(mountstart.sh gdsastart.sh start.sh)
chmod -cR 755 ${shfile[@]}
unset shfile

folder=(/system/mount/keys /system/servicekeys)
mkdir -p ${folder[@]}
unset folder

if [[ -f $MOUNT ]];then
   bash mountstart.sh
elif [[ -f $GDSA ]];then
     bash gdsastart.sh
else
   bash start.sh
fi

#E-O-F#

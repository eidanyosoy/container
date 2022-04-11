#!/usr/bin/with-contenv bash
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
function folders() {
folder="/mnt"
basefolder="/opt/appdata"
for fo in ${folder}; do
    $(which mkdir) -p \
       $fo/{unionfs,downloads,incomplete,torrent,nzb} \
       $fo/{incomplete,downloads}/{nzb,torrent}/{complete,temp,movies,tv,tv4k,movies4k,movieshdr,tvhdr,remux} \
       $fo/downloads/torrent/{temp,complete}/{movies,tv,tv4k,movies4k,movieshdr,tvhdr,remux} \
       $fo/{torrent,nzb}/watch

    $(which find) $fo -exec $(which chmod) a=rx,u+w {} \;
    $(which find) $fo -exec $(which chown) -hR 1000:1000 {} \;
done

for app in ${basefolder}; do
    $(which mkdir) -p $app/{compose,system,traefik}
    $(which find) $app -exec $(command -v chmod) a=rx,u+w {} \;
    $(which find) $app -exec $(command -v chown) -hR 1000:1000 {} \;
done
}
folder

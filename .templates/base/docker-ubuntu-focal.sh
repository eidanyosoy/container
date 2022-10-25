#!/bin/bash
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
# shellcheck disable=SC2046

FOLDER=$1
APP=$2
USERNAME=$3
TOKEN=$4

### APP SETTINGS ###
APPLINK="https://api.github.com/repos/dockserver/dockserver"
BUILDVERSION=$(curl -sX GET "https://registry.hub.docker.com/v2/repositories/library/alpine/tags" \
   | jq --raw-output '.[] | select(.name | contains(".")) | .name' \
   | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
BUILDVERSION="${BUILDVERSION#*v}"
BUILDVERSION="${BUILDVERSION#*release-}"
BUILDVERSION="${BUILDVERSION}"

BUILDIMAGE="alpine"

PICTURE="./images/$APP.png"
APPFOLDER="./$FOLDER/$APP"

## RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${BUILDVERSION}'",
   "baseimage": "'${BUILDIMAGE}'",
   "description": "Docker image  for '${APP}'",
   "body": "Upgrading '${APP}' to baseimage: '${BUILDIMAGE}':'${BUILDVERSION}'",
   "user": "dockserver image update[bot]"
}' > "./$FOLDER/$APP/release.json"


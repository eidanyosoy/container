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
NEWVERSION=$(curl -sX GET "https://registry.hub.docker.com/v1/repositories/library/alpine/tags" \
   | jq --raw-output '.[] | select(.name | contains(".")) | .name' \
   | sort -t "." -k1,1n -k2,2n -k3,3n | tail -n1)
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION#*release-}"
NEWVERSION="${NEWVERSION}"

## APP VERSION
APPVERSION=$(curl -sX GET "https://api.github.com/repos/dockserver/dockserver/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' | sed -e 's_^v__')
APPVERSION="${NEWVERSION#*v}"
APPVERSION="${NEWVERSION#*release-}"
APPVERSION="${NEWVERSION}"

HEADLINE="$(cat ./.templates/headline.txt)"
APPFOLDER="./$FOLDER/$APP"
##DESCRIPTION="$(curl -u $USERNAME:$TOKEN -sX GET "$APPLINK" | jq -r '.description')"
BASEIMAGE="alpine"
DESCRIPTION=" !!! DEVERLOP STATUS !!!
   DO NOT TRY TO PULL THE IMAGE
   YOU NEED ACCESS TO THE REPOSITORY"

### RELEASE SETTINGS ###

echo '{
   "appname": "'${APP}'",
   "apppic": "'${PICTURE}'",
   "appfolder": "./'$FOLDER'/'$APP'",
   "newversion": "'${NEWVERSION}'",
   "appversion": "'${APPVERSION}'",
   "baseimage": "'${BASEIMAGE}'",
   "description": "'${DESCRIPTION}'",
   "body": "Upgrading '${APP}' to '${NEWVERSION}'",
   "user": "github-actions[bot]"
}' > "./$FOLDER/$APP/release.json"


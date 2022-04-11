#!/bin/bash
####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THE DOCKER ARE UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
# shellcheck disable=SC2086
# shellcheck disable=SC2006
## add repositories apk parts
cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

### OS VALIDATION
function start() {
## case 1 = os
case "$1" in
   ubuntu|debian ) clear && os ;;
   *) clear && exit ;;
esac
}

### EXECUTIVE VALIDATION
function os() {
## case 2 = function to execute
source /app/function/function.sh
case "$2" in
   folder ) clear && folder ;;
   *) clear && exit ;;
esac
}

######
function startno() {

echo " some crazy stuff is coming || stay tune "
sleep 10
exit 0

}

startno

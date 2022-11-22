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
function log() {
   GRAY="\033[0;37m"
   BLUE="\033[0;34m"
   NC="\033[0m"
   $(which echo) -e "${GRAY}[$($(which date) +'%Y/%m/%d %H:%M:%S')]${BLUE} [Uploader]${NC} ${1}"
}

if pgrep -f "[n]ginx:" > /dev/null; then
    echo "Zombie nginx processes detected, sending SIGTERM"
    pkill -ef [n]ginx:
    $(which sleep) 1
fi

if pgrep -f "[n]ginx:" > /dev/null; then
    echo "Zombie nginx processes still active, sending SIGKILL"
    pkill -9 -ef [n]ginx:
    $(which sleep) 1
fi

source /app/uploader/function.sh && lang

log "${startupnginx}"

exec /usr/sbin/nginx -c /etc/nginx/nginx.conf

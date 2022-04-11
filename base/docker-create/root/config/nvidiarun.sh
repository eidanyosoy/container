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

mkdir -p /opt/nvidia

black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
normal=$(tput sgr0)


VERSION=510.54
RCHK=$(ls /etc/apt/sources.list.d/ 1>/dev/null 2>&1 | grep -qE 'nvidia' && echo true || echo false)
DREA=$(pidof dockerd) 1>/dev/null 2>&1 && echo true || echo false)
CHKN=$(which nvidia-smi) 1>/dev/null 2>&1 && echo true || echo false)
DCHK=$(cat /etc/docker/daemon.json | grep -qE 'nvidia' && echo true || echo false)

NSO=$(curl -s -L https://nvidia.github.io/nvidia-docker/$DIST/nvidia-docker.list)
NSOE=$(echo ${NSO} | grep -E 'Unsupported')
if [[ $NSOE != "" ]]; then
printf "%1s\n" "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      NVIDIA ❌ ERROR
      NVIDIA don't support your running Distribution
      Installed Distribution = ${DIST}
      Please visit the link below to see all supported Distributionen
      NVIDIA ❌ ERROR
      ${NSO}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${normal}"
     read -erp "Confirm Info | Type confirm & PRESS [ENTER]" input </dev/tty
if [[ "$input" = "confirm" ]]; then clear; else subos; fi
fi

if [[ ! -f "/opt/nvidia/nvidia.run" ]]; then
   $(which mkdir) /opt/nvidia && \
   $(which wget) -O /opt/nvidia/nvidia.run https://international.download.nvidia.com/XFree86/Linux-x86_64/$VERSION/NVIDIA-Linux-x86_64-$VERSION.run && \
   $(which chmod) +x ./nvidia.run && \
   ./opt/nvidia/nvidia.run --dkms --silent
   if test -f "/opt/nvidia/nvidia.run"; then
      $(which rm) -rf /opt/nvidia/nvidia.run
   fi
fi

if [[ $RCHK == "false" ]]; then
   $(which apt) install $(apt-cache search 'nvidia-driver-' | grep '^nvidia-driver-[[:digit:]]*' | tail -n1 | awk '{print $1}') -y
   $(which curl) -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
     apt-key add -
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
   $(which curl) -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
     tee /etc/apt/sources.list.d/nvidia-container-runtime.list
   $(which apt) update -y && \
   $(which apt) install nvidia-container-runtime nvidia-container-toolkit -y
fi

if [[ $DCHK == "false" ]]; then
$(which mkdir) -p /etc/systemd/system/docker.service.d
$(which tee) /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
EOF
$(which systemctl) daemon-reload && $(which systemctl) restart docker
$(which tee) /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
$(which pkill) -SIGHUP dockerd
fi

if [[ ! -d "/opt/nvidia/libnvidia-encode-backup" ]];then
   $(which wget) -O /opt/nvidia/nvidia-patch.sh https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh && \
   chmod +x /opt/nvidia/nvidia-patch.sh && |
   ./opt/nvidia/nvidia-patch.sh
   if test -f "/opt/nvidia/nvidia-patch.sh"; then
      $(which rm) -rf /opt/nvidia/nvidia-patch.sh
   fi
fi

if [[ $(which nvidia-smi) ]];then
   SHOW=$(nvidia-smi)
printf "%1s\n" "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      NVIDIA OUTPUT
   ${SHOW}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${normal}"
fi

if [[ $GVID == "false" ]]; then usermod -aG video $(whoami); fi
if [[ $DREA == "true" ]]; then pkill -SIGHUP dockerd; fi

if [[ $DEVT != "false" ]]; then
   $(which chmod) -R 750 /dev/dri
else
printf "%1s\n" "${red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You need to restart the server to get access to /dev/dri
after restarting execute the install again
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${normal}"
read -p "Type confirm to reboot: " input
    if [[ "$input" = "confirm" ]]; then reboot -n; else endcommand; fi
fi

if [[ $DREA == "true" && $DCHK == "true" && $CHKN == "true" && $DEVT != "false" ]]; then echo "nvidia-container-runtime is working"; else echo "nvidia-container-runtime is not working"; fi 


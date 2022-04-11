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
mkdir -p /opt/hetzner/

HMOD=$(ls /etc/modprobe.d/ | grep -qE 'hetzner' && echo true || echo false)
ITEL=$(cat /etc/modprobe.d/blacklist-hetzner.conf | grep -qE '#blacklist i915' && echo true || echo false)
IMOL1=$(cat /etc/default/grub | grep -qE '#GRUB_CMDLINE_LINUX_DEFAULT' && echo true || echo false)
IMOL2=$(cat /etc/default/grub.d/hetzner.cfg | grep -qE '#GRUB_CMDLINE_LINUX_DEFAULT' && echo true || echo false)
INTE=$(ls /usr/bin/intel_gpu_* 1>/dev/null 2>&1 && echo true || echo false)
VIFO=$(which vainfo 1>/dev/null 2>&1 && echo true || echo false)

if [[ $HMOD == "false" ]]; then exit; fi
if [[ $ITEL == "false" ]]; then sed -i "s/blacklist i915/#blacklist i915/g" /etc/modprobe.d/blacklist-hetzner.conf; fi
if [[ $IMOL1 == "false" ]]; then sed -i "s/GRUB_CMDLINE_LINUX_DEFAUL/#GRUB_CMDLINE_LINUX_DEFAUL/g" /etc/default/grub; fi
if [[ $IMOL2 == "false" ]]; then sed -i "s/GRUB_CMDLINE_LINUX_DEFAUL/#GRUB_CMDLINE_LINUX_DEFAUL/g" /etc/default/grub.d/hetzner.cfg; fi
if [[ $OSVE == "ubuntu" && $VERS == "focal" ]]; then
   if [[ $IMOL1 == "true" && $IMOL2 == "true" && $ITEL == "true" ]]; then sudo update-grub; fi
else
   if [[ $IMOL1 == "true" && $IMOL2 == "true" && $ITEL == "true" ]]; then sudo grub-mkconfig -o /boot/grub/grub.cfg; fi
fi
if [[ $GCHK == "false" ]]; then groupadd -f video; fi
if [[ $GVID == "false" ]]; then usermod -aG video $(whoami); fi

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

if [[ $VIFO == "false" ]]; then $(command -v apt) install vainfo -yqq; fi
if [[ $INTE == "false" && $IGPU == "true" ]]; then $(command -v apt) update -yqq && $(command -v apt) install intel-gpu-tools -yqq; fi
if [[ $IMOL1 == "true" && $IMOL2 == "true" && $ITEL == "true" && $GVID == "true" && $DEVT == "true" ]]; then echo "Intel IGPU is working"; else echo "Intel IGPU is not working"; fi


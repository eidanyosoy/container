#!/bin/bash


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

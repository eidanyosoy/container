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

mkdir -p /opt/lxc
cat > /opt/lxc/.lxcstart.sh << EOF; $(echo)
#!/bin/bash
#
# Title:      LXC Bypass the mount :shared
# OS Branch:  ubuntu,debian,rasbian
# Author(s):  mrdoob
# Coauthor:   DrAgOn141
# GNU:        General Public License v3.0
################################################################################
## make / possible to add /mnt:shared
mount --make-shared /
EOF

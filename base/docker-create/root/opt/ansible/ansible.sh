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
function ansible() {
if [[ ! -d "/etc/ansible/inventories" ]]; then $(which mkdir) -p $invet ; fi
cat > /etc/ansible/inventories/local << EOF; $(echo)
## CUSTOM local inventories
[local]
127.0.0.1 ansible_connection=local
EOF
if test -f /etc/ansible/ansible.cfg; then
   $(which mv) /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.bak
fi
cat > /etc/ansible/ansible.cfg << EOF; $(echo)
## CUSTOM Ansible.cfg
[defaults]
deprecation_warnings = False
command_warnings = False
force_color = True
inventory = /etc/ansible/inventories/local
retry_files_enabled = False
EOF
}

ansible

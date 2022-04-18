#!/usr/bin/env bash                                                                           
LFOLDER=/tmp

if [[ "${GIT_REPO}" != "" ]];then
   GIT_REPO=${GIT_REPO}
   ## valide if exists
   $(which git) ls-remote ${GIT_REPO} -q
   if [[ $? != 0 ]];then
      GIT_REPO=https://github.com/dockserver/apps.git
   fi
else
   GIT_REPO=https://github.com/dockserver/apps.git
fi
              
if [ "$(ls -1p /opt/appdata/compose)" ];then                                                  
   $(which git) clone ${GIT_REPO} /tmp/apps --quiet
   rm -rf /tmp/apps/.git /tmp/apps/upstream.sh /tmp/apps/README.md
   $(which rsync) "${LFOLDER}/apps/" /opt/appdata/compose/ -aqhv
   rm -rf /tmp/apps/*
fi
chown -cR 1000:1000 /opt/appdata/compose &>/dev/null
                                                                                         
/env/bin/gunicorn --chdir /app main:app -w 4 --threads 8 -b 0.0.0.0:5000

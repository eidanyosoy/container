#!/usr/bin/env bash
LFOLDER=/tmp

if [ "$(ls -1p /opt/appdata/compose)" ];then
   $(which git) clone git@github.com:dockserver/apps.git -C "${LFOLDER}/" --quiet
   $(which rsync) "${LFOLDER}/" /opt/appdata/compose/ -aqhv
fi

/env/bin/gunicorn --chdir /app main:app -w 2 --threads 4 -b 0.0.0.0:5000


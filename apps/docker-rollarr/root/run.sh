#!/bin/bash

if [[ ! -f "/config/data.json" ]]; then
   cp /rollarr/data_sample.json /config/data.json
fi

chmod -R 755 /rollarr \  
          /config/data.json \
          /crontab &>/dev/null

chown -cR abc:abc /rollarr \
         /config/data.json \
         /crontab &>/dev/null

exec cron -f & \
exec python /rollarr/Preroll.py

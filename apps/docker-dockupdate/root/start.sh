#!/usr/bin/with-contenv bash
# shellcheck shell=bash
#####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
# CODE OWNER
# USER : methatronc
# LINK : https://github.com/methatronc/checker
#####################################
# THIS DOCKER IS UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196
# shellcheck disable=SC2046

apk --quiet --no-cache --no-progress update && \
apk --quiet --no-cache --no-progress upgrade && \
apk --quiet --no-cache --no-progress add curl unzip shadow bash bc findutils coreutils && \
apk --quiet --no-cache --no-progress add docker-cli jq curl wget && \
apk del --quiet --clean-protected --no-progress && \
rm -rf /var/cache/apk/* /tmp/* /sbin/halt /sbin/poweroff /sbin/reboo

echo "***Install done***"

DISCORD=$1

while true; do
   echo "Starting Dock Update Bot"

   docker ps --format "{{.Image}}" >images.list
   discord=https://discord.com/api/webhooks/${DISCORD}

   uniq images.list.tmp images.list
   rm -f images.list.tmp
   list=""

   while read line; do
      if [ "$(echo $line | grep \/)" == "" ]; then
         line=library/$line
      fi
      image=$(echo $line | cut -d : -f 1 | sed 's/ghcr.io\///' | sed 's/lscr.io\///')
      tag=$(echo $line | cut -d : -f 2 | sed 's/ghcr.io\///' | sed 's/lscr.io\///')
      last_updated=""
      page=1
      if [ "$tag" == "$image" ]; then
         tag="latest"
      fi
      while [ "$last_updated" == "" ]; do
         repo=$(curl --silent "https://hub.docker.com/v2/repositories/$image/tags?page=$page")
         if [ "$repo" == "{\"count\":0,\"next\":null,\"previous\":null,\"results\":[]}" ]; then
            last_updated="1970-01-01T00:00:00.000000Z"
         else
            last_updated=$(echo $repo | jq --arg tag "$tag" '.results[] | select(.name==$tag) | .last_updated')
         fi
         page=$(expr "$page" + 1)
      done
      current_epoch=$(expr "$(date '+%s')" - 86400)
      last_updated_epoch=$(date -d $(echo $last_updated | cut -d \" -f 2) '+%s')
      if [ "$last_updated_epoch" \> "$current_epoch" ]; then
         list=$list$(echo "\n\`$line\`")
      else
         echo "No update for $line since yesterday."
      fi
   done <images.list
   ## SEND DISCORD ##
   text=\""Docker Image update is available for \n$(echo $list)"\"
   curl -H "Content-Type: application/json" -d "{\"username\": \"Dock-Update-BOT\",\"embeds\":[{\"description\": $text, \"title\":\"Docker Image Update Bot\", \"color\":2960895}]}" $discord
   echo "SLEEPING 10MINS"
   sleep 10m
done
#<">#

##~# $(command -v docker) run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro ghcr.io/dockserver/dockupdate:master DS=WEBHOOKId

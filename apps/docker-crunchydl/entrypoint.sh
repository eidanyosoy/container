#!/bin/bash
####################################
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
# shellcheck disable=SC2086
# shellcheck disable=SC2046

if [[ ! -n "${EMAIL}" ]];then
   $(which echo) "**** NO EMAIL WAS SET *****" && $(which sleep) infinity
fi

if [[ ! -n "${PASSWORD}" ]];then
   $(which echo) "**** NO PASSWORD WAS SET ****" && $(which sleep) infinity
fi

$(which echo) "**** install packages ****" && \
  $(which apt) update -y &>/dev/null && \
    $(which apt) upgrade -y &>/dev/null
      $(which apt) install wget jq rsync curl locales libavcodec-extra ffmpeg -y &>/dev/null

### READ TO DOWNLOAD FILE ###
CHK=/config/download.txt
### FINAL FOLDER ###

while true ; do
  CHECK=$($(which cat) ${CHK} | wc -l)
  if [ "${CHECK}" -gt 0 ]; then
     ### READ FROM FILE AND PARSE ###
     $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra SHOWLINK ; do
        $(which echo) "**** downloading now ${SHOWLINK[1]} ****"
       ./aniDL --username ${EMAIL} --password ${PASSWORD} --new \
       --service ${SHOWLINK[0]} --series ${SHOWLINK[1]} \
       -q 0 --dlsubs all --dubLang ${SHOWLINK[2]} \
       --filename=${showTitle}.${title}.S${season}E${episode}.WEBHD.${height} \
       --force Y --mp4 --nocleanup --skipUpdate
  else
      $(which echo) "**** nothing to download yet ****" && \
         $(which sleep) 240
  fi
done

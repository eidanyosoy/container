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

while true; do
   if [[ ! -f /config/download.txt ]];then
      $(which echo) "**** NO download.txt found ****" && break
   else
      break
   fi
done
   

### READ TO DOWNLOAD FILE ###
CHK=/config/download.txt
LOCHK=/config/to-download.txt

## RUN LOOP ##
function reloop() {
  ## GET NEWS FILES ##
  ./aniDL \
  --username ${EMAIL} --password ${PASSWORD} \
  --service ${SERVICE} --new > /config/newfiles
  cat /config/newfiles | grep -e "Season" | grep -E "Z:" | sed 's/[#$%*@]//g' | cut -d: -f2 | awk '{print $1}' | while IFS=$'|' read -ra SHOWLINK ; do
     echo "tv|${SHOWLINK}" >> "${CHK}"
  done
}
## LOGIN 
./aniDL --username ${EMAIL} --password ${PASSWORD} --service ${SERVICE}

while true ; do
  CHECK=$($(which cat) ${CHK} | wc -l)
  if [ "${CHECK}" -gt 0 ]; then
     ### READ FROM FILE AND PARSE ###
       $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra SHOWLINK ; do
         ./aniDL --username ${EMAIL} --password ${PASSWORD} \
         --series "${SHOWLINK[1]}" \
         --videoTitle ${title} --all --dubLang "${DUBLANG}" \
         --service "${SERVICE}" --videoTitle ${title} \
         --force Y --mp4 --nocleanup --skipUpdate --all
         shopt -s globstar
         for f in /videos/**/*.mp4; do
             $(which mv) "$f" "${f// /.}" &>/dev/null
         done
         $(which sed) -i 1d "${CHK}"
         ## RUN FFMPEG TO COVENT TO MKV ###
         shopt -s globstar
         for f in /videos/**/*.mp4; do
             ## c:v/s/a >> video _ subtitle _ audio  >> copy from mp4
             $(which echo) "**** running  convert for ${f} ****" && \
             $(which ffmpeg) -nostdin -i "$f" -c:v copy -c:a copy -c:s copy "${f%.mp4}-dockserver.mkv" &>/dev/null
             $(which chown) -cR 1000:1000 "$f" &>/dev/null && \
             $(which rm) -rf "{$f}.mp4" &>/dev/null 
         done
         if [[ $(date +%H:%M) == "00:01" ]];then reloop ; fi
      done
  else
      $(which echo) "**** nothing to download yet ****" && \
         $(which sleep) 240
  fi
done

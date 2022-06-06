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
LOCHK=/config/to-download.txt

## RUN LOOP ##

while true ; do
  CHECK=$($(which cat) ${CHK} | wc -l)
  if [ "${CHECK}" -gt 0 ]; then
     ### READ FROM FILE AND PARSE ###
       $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra SHOWLINK ; do
          if [[ "${SHOWLINK[0]}" == tv ]]; then
              $(which echo) "**** downloading now ${SHOWLINK[1]} ****"
              ./aniDL \
              --username ${EMAIL} --password ${PASSWORD} --new \
              --service ${SERVICE} --series ${SHOWLINK[1]} \
              --videoTitle ${title} --dubLang ${DUBLANG} \
              --filename=${SHOWLINK[0]}/${showTitle}/${showTitle}.${title}.S${season}E${episode}.WEBHD.${height} \
              --force Y --mp4 --nocleanup --skipUpdate
          elif [[ "${SHOWLINK[0]}" == movie ]]; then
              $(which echo) "**** downloading now ${SHOWLINK[1]} ****"
              ./aniDL \
              --username ${EMAIL} --password ${PASSWORD} --new \
              --service ${SERVICE} --movie-listing ${SHOWLINK[1]} \
              --videoTitle ${title} --dubLang ${DUBLANG} \
              --filename=${SHOWLINK[0]}/${title}/${showTitle}.${title}.WEBHD.${height} \
              --force Y --mp4 --nocleanup --skipUpdate
          else
              $(which echo) "**** could not terminate what you want to load ...... atsch .... ****" 
          fi
          shopt -s globstar
          for f in /videos/${SHOWLINK[0]}/**/*.mp4; do
             $(which mv) "$f" "${f// /.}" &>/dev/null
          done
          $(which cat) "${CHK}" | awk 'NR==1; END{print}' >> "${LOCHK}"
          $(which sed) -i 1d "${CHK}"
          ## RUN FFMPEG TO COVENT TO MKV ###
          shopt -s globstar
          for f in /videos/**/*.mp4; do
             ## c:v/s/a >> video _ subtitle _ audio  >> copy from mp4
             $(which echo) "**** running  convert for ${f} ****" && \
             $(which ffmpeg) -nostdin -i "$f" -c:v copy -c:a copy -c:s copy "${f%.mp4}-dockserver.mkv" && \
             $(which chown) -cR 1000:1000 "$f" &>/dev/null && \
             $(which rm) -rf "{$f}.mp4" &>/dev/null 
          done
          CHECK=$($(which cat) ${CHK} | wc -l)
          if [ "${CHECK}" == 0 ]; then
             $(which mv) "${LOCHK}" "${CHK}"
          fi
       done
  else
      $(which echo) "**** nothing to download yet ****" && \
         $(which sleep) 240
  fi
done

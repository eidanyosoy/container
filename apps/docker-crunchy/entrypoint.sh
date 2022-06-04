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
    $(which apt) upgrade -y &>/dev/null && \
      $(which apt) install wget jq rsync curl locales libavcodec-extra ffmpeg -y &>/dev/null

### CREATE BASIC FOLDERS ###
$(which echo) "**** setup folders ****" && \
  $(which mkdir) -p /app/{crunchy,downloads} && \
    $(which rm) -rf /config/log && \
      $(which mkdir) -p /config/log

### REMOVE EXISTING ###
if [[ -f "/app/crunchy/crunchy" ]]; then
   $(which rm) -rf /app/crunchy/crunchy &>/dev/null
fi

### GET LATEST VERSION ###
$(which echo) "**** Install requirements ****" && \
  VERSION=$(curl -sX GET "https://api.github.com/repos/ByteDream/crunchyroll-go/releases/latest" | jq --raw-output '.tag_name')
    $(which wget) https://github.com/ByteDream/crunchyroll-go/releases/download/${VERSION}/crunchy-${VERSION}_linux -O /app/crunchy/crunchy &>/dev/null
      $(which chmod) a+x /app/crunchy/crunchy && \
        $(which chmod) 777 /app/crunchy/crunchy

### RUN LOGIN ###
$(which echo) "**** login into crunchyroll as ${EMAIL} with ${PASSWORD} ****"
  /app/crunchy/crunchy login ${EMAIL} ${PASSWORD} --persistent &>/dev/null

### READ TO DOWNLOAD FILE ###
CHK=/config/download.txt
### FINAL FOLDER ###
FINAL=/mnt/downloads/crunchy

## REMOVE OLD FOLDERS ##
if [[ -d /app/downloads ]];then
   $(which rm) -rf /app/downloads
fi

### SETTING FOR LANGUAGE  ###
LANGUAGESET=${LANGUAGESET}
if [[ ! -n "${LANGUAGESET}" ]];then
   LANGUAGESET=en-US
fi
LANGUAGETAG=${LANGUAGETAG}
if [[ ! -n "${LANGUAGESET}" ]];then
   LANGUAGESET=ENGLISH
fi

export LANGUAGESET=${LANGUAGESET}
export LANGUAGETAG=${LANGUAGETAG}

$(which echo) "**** LANGUAGESET is set to ${LANGUAGESET} ****" && \
  $(which echo) "**** LANGUAGETAG is set to ${LANGUAGETAG} ****"

###ar-SA, de-DE, en-US, es-419, es-ES, fr-FR, it-IT, ja-JP, pt-BR, pt-PT, ru-RU

#### RUN LOOP ####
while true ; do
  CHECK=$($(which cat) ${CHK} | wc -l)
  if [ "${CHECK}" -gt 0 ]; then
     ### READ FROM FILE AND PARSE ###
     $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra SHOWLINK ; do
        $(which echo) "**** downloading now ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
        $(which sed) -i 1d "${CHK}"
        if [[ "${SHOWLINK[0]}" == tv ]]; then
           $(which mkdir) -p ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null && \
           $(which touch) /config/log/${SHOWLINK[1]}
           ### DOWNLOAD SHOW ###
           /app/crunchy/crunchy archive \
           --resolution best \
           --language ${LANGUAGESET} \
           --directory ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} \
           --merge video \
           --goroutines 8 \
           --output "{series_name}.S{season_number}E{episode_number}.{title}.${LANGUAGETAG}.DL.DUBBED.{resolution}.WebHD.AAC.H264-dockserver.mkv" \
           ${SHOWLINK[2]} > /config/log/${SHOWLINK[1]}
        elif [[ "${SHOWLINK[0]}" == movie ]]; then
             $(which mkdir) -p ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null && \
             $(which touch) /config/log/${SHOWLINK[1]}
             ### DOWNLOAD MOVIE ###
             /app/crunchy/crunchy archive \
             --resolution best \
             --language ${LANGUAGESET} \
             --directory ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} \
             --merge video \
             --goroutines 8 \
             --output "{series_name}.{title}.${LANGUAGETAG}.DL.DUBBED.{resolution}.WebHD.AAC.H264-dockserver.mkv" \
             ${SHOWLINK[2]} > /config/log/${SHOWLINK[1]}
         else
             $(which sed) -i 1d "${CHK}" && break
         fi
         if [ $? -ne 0 ]; then
            echo "**** ERROR --- DOWNLOAD FAILED ****" && break
         else
            $(which rm) -rf /config/log/${SHOWLINK[1]}
         fi
         $(which echo) "**** downloading complete ${SHOWLINK[1]} into ${SHOWLINK[0]} ****" && \
         $(which echo) "**** rename now ${SHOWLINK[1]} into ${SHOWLINK[0]} *****"
         for f in ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]}/*; do
             $(which mv) "$f" "${f// /.}" &>/dev/null
         done
         for f in ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]}/*; do
             ### REMOVE CC FORMAT ###
             $(which mv) "$f" "${f//1920x1080/1080p}" &>/dev/null
             $(which mv) "$f" "${f//1280x720/720p}" &>/dev/null
             $(which mv) "$f" "${f//640x480/SD}" &>/dev/null
             $(which mv) "$f" "${f//480x360/SD}" &>/dev/null
         done
         $(which echo) "**** rename completely ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
         $(which echo) "**** setting permissions now ${SHOWLINK[1]} into ${SHOWLINK[0]} *****" && \
         $(which chown) -cR 1000:1000 ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null && \
         $(which echo) "**** setting permissions completely ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
      done
  else
      $(which echo) "**** nothing to download yet ****" && \
         $(which sleep) 240
  fi
done

## EOF

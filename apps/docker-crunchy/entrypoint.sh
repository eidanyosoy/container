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
    echo "**** NO EMAIL WAS SET *****" && $(which sleep) infinity
fi

if [[ ! -n "${PASSWORD}" ]];then
    echo "**** NO PASSWORD WAS SET ****" && $(which sleep) infinity
fi

echo "**** install packages ****" && \
  $(which apt) update -y &>/dev/null && \
    $(which apt) upgrade -y &>/dev/null && \
      $(which apt) install wget jq rsync curl locales libavcodec-extra ffmpeg -y &>/dev/null

### CREATE BASIC FOLDERS ###
echo "**** setup folders ****" && \
  $(which mkdir) -p /app/{crunchy,downloads} && \
    $(which mkdir) -p /config/log

### REMOVE EXISTING ###
if [[ -f "/app/crunchy/crunchy" ]]; then
   $(which rm) -rf /app/crunchy/crunchy &>/dev/null
fi

### GET LATEST VERSION ###
echo "**** Install requirements ****" && \
  VERSION=$(curl -sX GET "https://api.github.com/repos/ByteDream/crunchyroll-go/releases/latest" | jq --raw-output '.tag_name')
    $(which wget) https://github.com/ByteDream/crunchyroll-go/releases/download/${VERSION}/crunchy-${VERSION}_linux -O /app/crunchy/crunchy &>/dev/null
      $(which chmod) a+x /app/crunchy/crunchy && \
        $(which chmod) 777 /app/crunchy/crunchy

### RUN LOGIN ###
echo "**** login into crunchyroll as ${EMAIL} with ${PASSWORD} ****"
  /app/crunchy/crunchy login ${EMAIL} ${PASSWORD} --persistent &>/dev/null

### READ TO DOWNLOAD FILE ###
CHK=/config/download.txt
### TEMP DOWNLOAD LOCATION ###
TMP=/app/downloads
### FINAL FOLDER ###
FINAL=/mnt/downloads/crunchy

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

echo "**** LANGUAGESET is set to ${LANGUAGESET} ****" && \
  echo "**** LANGUAGETAG is set to ${LANGUAGETAG} ****"

sleep 5

###ar-SA, de-DE, en-US, es-419, es-ES, fr-FR, it-IT, ja-JP, pt-BR, pt-PT, ru-RU

#### RUN LOOP ####

while true ; do
  CHECK=$($(which cat) ${CHK} | wc -l)
  if [ "${CHECK}" -gt 0 ]; then
     ### READ FROM FILE AND PARSE ###
     $(which cat) "${CHK}" | head -n 1 | while IFS=$'|' read -ra SHOWLINK ; do

        echo "**** downloading now ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
        $(which sed) -i 1d "${CHK}"
        ### CREATE FOLDER ###
        ### sample : .../tv or movie/show or movie name/filename....
        $(which mkdir) -p ${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null
        $(which touch) /config/log/${SHOWLINK[1]}
        if [[ "${SHOWLINK[0]}" == tv ]]; then

           ### DOWNLOAD SHOW ###
           /app/crunchy/crunchy archive \
           --resolution best \
           --language ${LANGUAGESET} \
           --directory ${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]} \
           --merge auto \
           --goroutines 8 \
           --output "{series_name}.S{season_number}E{episode_number}.{title}.${LANGUAGETAG}.DL.DUBBED.{resolution}.WebHD.AAC.H264-dockserver.mkv" \
           https://www.crunchyroll.com/${SHOWLINK[1]} > /config/log/${SHOWLINK[1]}
           retVal=$?

        elif [[ "${SHOWLINK[0]}" == movie ]]; then

             ### DOWNLOAD MOVIE ###
             /app/crunchy/crunchy archive \
             --resolution best \
             --language ${LANGUAGESET} \
             --directory ${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]} \
             --merge auto \
             --goroutines 8 \
             --output "{series_name}.{title}.${LANGUAGETAG}.DL.DUBBED.{resolution}.WebHD.AAC.H264-dockserver.mkv" \
             https://www.crunchyroll.com/${SHOWLINK[1]} > /config/log/${SHOWLINK[1]}
             retVal=$?

         else
             $(which sed) -i 1d "${CHK}" && break
         fi

         if [ $retVal -ne 0 ]; then
            echo "**** ERROR --- DOWNLOAD FAILED ****" && break
         else
            $(which rm) -rf /config/log/${SHOWLINK[1]}
         fi

         echo "**** downloading complete ${SHOWLINK[1]} into ${SHOWLINK[0]} ****" && \
         sleep 5 && \
         echo "**** rename now ${SHOWLINK[1]} into ${SHOWLINK[0]} *****"

         ### FIRST RENAME ###
         if [[ -d "${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]}" ]]; then
            for f in ${TMP}/${SHOWLINK[0]}/*/*; do
                ### REPLACE EMPTY SPACES WITH DOTS ####
                $(which mv) "$f" "${f// /.}" &>/dev/null
             done
         fi

         if [[ -d "${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]}" ]]; then
            ### SECONDARY RENAME ###
            for f in ${TMP}/${SHOWLINK[0]}/${SHOWLINK[1]}/*; do
                ### REMOVE CC FORMAT ###
                $(which mv) "$f" "${f//1920x1080/1080p}" &>/dev/null
                $(which mv) "$f" "${f//1280x720/720p}" &>/dev/null
                $(which mv) "$f" "${f//640x480/SD}" &>/dev/null
                $(which mv) "$f" "${f//480x360/SD}" &>/dev/null
            done
            echo "**** rename completely ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
         fi
         sleep 5 && \
         echo "**** moving now ${SHOWLINK[1]} into ${SHOWLINK[0]} *****"
         ### MOVE ALL FILES FOR THE ARRS ###
         $(which mkdir) -p ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null
         ### moved to rsync ###
         $(which rsync) --remove-source-files -zvh ${TMP}/${SHOWLINK[0]} ${FINAL}/${SHOWLINK[0]} &>/dev/null
         $(which chown) -cR 1000:1000 ${FINAL}/${SHOWLINK[0]}/${SHOWLINK[1]} &>/dev/null
         $(which find) ${TMP}/${SHOWLINK[0]} -type d -empty -delete &>/dev/null
         echo "**** moving completely ${SHOWLINK[1]} into ${SHOWLINK[0]} ****"
      done
  else
      echo "**** nothing to download yet ****" && \
         $(which sleep) 240
  fi
done

## EOF

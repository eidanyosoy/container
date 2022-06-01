#!/bin/bash
$(which apt) update -yqq
$(which apt) upgrade -yqq
$(which apt) install wget jq curl locales ffmpeg -yqq

$(which mkdir) -p /app/{crunchy,downloads}

VERSION=$(curl -sX GET "https://api.github.com/repos/ByteDream/crunchyroll-go/releases/latest" | jq --raw-output '.tag_name')
$(which wget) --silent https://github.com/ByteDream/crunchyroll-go/releases/download/${VERSION}/crunchy-${VERSION}_linux -O /app/crunchy/crunchy
$(which chmod) a+x /app/crunchy/crunchy
$(which mkdir) -p /app/downloads

/app/crunchy/crunchy login ${EMAIL} ${PASSWORD} --persistent

CHK=/app/download.txt

#### RUN LOOP ####

while true ; do
   CHECK=$($(which cat) ${CHK} | wc -l)
   if [ "${CHECK}" -gt 0 ]; then
   ### READ FROM FILE AND PARSE ###
   $(which cat) /app/download.txt | head -n 1 | while IFS=$'|' | read -ra SHOWLINK ; do
     ### CREATE FOLDER ###
     $(which mkdir) -p /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]}
       if [[ "${SHOWLINK[0]}" == tv ]]; then
       ### DOWNLOAD SHOW ###
       /app/crunchy/crunchy archive \
        --resolution best \
        --language en-US \
        --language jp-Jp \
        --language de-DE \
        --directory /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]} \
        --merge auto \
        --goroutines 4 \
        --output "{series_name}.S{season_number}E{episode_number}.{title}.GERMAN.DL.DUBBED.{resolution}.WebHD.AC3.x264-dserver.mkv" \
        https://www.crunchyroll.com/${SHOWLINK[1]}

       elif [[ "${SHOWLINK[0]}" == tv ]]; then
       ### DOWNLOAD MOVIE ###
       /app/crunchy/crunchy archive \
        --resolution best \
        --language en-US \
        --language jp-Jp \
        --language de-DE \
        --directory /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]} \
        --merge auto \
        --goroutines 4 \
        --output "{series_name}.{title}.GERMAN.DL.DUBBED.{resolution}.WebHD.AC3.x264-dserver.mkv" \
        https://www.crunchyroll.com/${SHOWLINK[1]}

       else
         sed -i 1d /app/download.txt && break
       fi

       for f in /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]}/*; do
         ### REPLACE EMPTY SPACES WITH DOTS ####
         mv "$f" "${f// /.}"
         ### REMOVE CC FORMAT ###
         if grep -Fxq "1080" "$f" ;then
            mv "$f" "${f//1920x1080/1080p}"
         elif grep -Fxq "720" "$f" ;then
            mv "$f" "${f//1280x720/720p}"
         elif grep -Fxq "480" "$f" ;then
            mv "$f" "${f//640x480/SD}"
         elif grep -Fxq "360" "$f" ;then
            mv "$f" "${f//480x360/SD}"
         else
            echo " can't find result "
         fi

         $(which chown) -cR 1000:1000 /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]}
         $(which mkdir) /mnt/downloads/crunchy/${SHOWLINK[0]}
         $(which mv) /app/downloads/${SHOWLINK[0]}/${SHOWLINK[1]} /mnt/downloads/crunchy/${SHOWLINK[0]}/${SHOWLINK[1]}

      done
      ### REMOVE LINE ###
      $(which sed) -i 1d /app/download.txt
   done
   else
      $(which sleep) 240
   fi
done

## EOF

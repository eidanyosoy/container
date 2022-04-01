
### Muss durch gemappt  werden um die keys zu finden 
## check welche Apps es gibt 

for i in $(ls -d /opt/appdata/*/); do basename -- ${i%%/}; done
## Zeigt die arrs alle an
function arrs() {
for i in $(ls -d /apps/*/ | grep '*arr"'); do

    APP=$(basename -- ${APP%%/})
    KEY=$(cat /apps/$i/config.xml) 1>/dev/null 2>&1
    KEY=${KEY#*<ApiKey>} 1>/dev/null 2>&1
    
    if [ $APP == "sonarr" ]; then
       PORT=8989
    elif [ $APP == "radarr" ]; then
       PORT=7878
    elif [ $APP == "lidarr" ]; then
       PORT=8686
    elif [ $APP == "bazarr" ]; then
       PORT=6767
    elif [ $APP == "readarr" ]; then
       PORT=8787
    else
       echo "can't find any arr running "
    fi

    APIKEYECHO=$(curl -sX GET http://${APP}:${PORT}/api/rootfolder/1?apikey=$(echo ${KEY:0:32}) -H "accept: application/json" | jq -r '.|.path')

    echo "${APP} = ${APIKEYECHO} = ${KEY:0:32}" >> /config/arrkeys

done
}

PLEX_TOKEN=$(cat "/opt/appdata/plex/database/Library/Application Support/Plex Media Server/Preferences.xml" | sed -e 's;^.* PlexOnlineToken=";;' | sed -e 's;".*$;;' | tail -1)


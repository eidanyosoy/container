
### Muss durch gemappt  werden um die keys zu finden 
## check welche Apps es gibt 

for i in $(ls -d /opt/appdata/*/); do basename -- ${i%%/}; done
## Zeigt die arrs alle an

    sonarr=$(curl -sX GET http://sonarr:8989/api/rootfolder/1?apikey= apikey -H "accept: application/json" | jq -r '.|.path')
    sonarr4k=$(curl -sX GET http://sonarr4k:8989/api/rootfolder/1?apikey= apkiey -H "accept: application/json" | jq -r '.|.path')
    radarr=$(curl -sX GET http://radarr:7878/api/v3/rootfolder/1?apikey= apikey -H "accept: application/json" | jq -r '.|.path')
    radarr4k=$(curl -sX GET http://radarr4k:7878/api/v3/rootfolder/1?apikey= apikey -H "accept: application/json" | jq -r '.|.path')

echo "sonarr = $sonarr"
echo "sonarr4k = $sonarr4k"
echo "radarr = $radarr"
echo "radarr4k = $radarr4k"

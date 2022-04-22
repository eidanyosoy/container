#!/bin/bash
####################################
# All rights reserved.              #
# started from Zero                 #
# Docker owned dockserver           #
# Docker Maintainer dockserver      #
#####################################
#####################################
# THE DOCKER ARE UNDER LICENSE      #
# NO CUSTOMIZING IS ALLOWED         #
# NO REBRANDING IS ALLOWED          #
# NO CODE MIRRORING IS ALLOWED      #
#####################################
# shellcheck disable=SC2086
# shellcheck disable=SC2006
## add repositories apk parts
cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

echo "**** update packages ****" && \
    apk --quiet --no-cache --no-progress update && \
    apk --quiet --no-cache --no-progress upgrade

echo "**** install build packages ****" && \
    apk add -U --update --no-cache \
       bash \
       ca-certificates \
       shadow \
       musl \
       findutils \
       coreutils \
       py-pip \
       python3-dev \
       libffi-dev \
       openssl-dev \
       gcc \
       libc-dev \
       make \
       docker

   python -m pip install --no-warn-script-location --upgrade pip setuptools && \
   pip install --no-warn-script-location --no-cache-dir cryptography && \
   pip install --no-warn-script-location --no-cache-dir docker-compose==1.29.2

 echo "*** cleanup system ****" && \
    apk del --quiet --clean-protected --no-progress && \
    rm -f /var/cache/apk/*

echo '{
    "storage-driver": "overlay2",
    "userland-proxy": false,
    "dns": ["8.8.8.8", "1.1.1.1"],
    "ipv6": false,
    "log-driver": "json-file",
    "live-restore": true,
    "log-opts": {"max-size": "8m", "max-file": "2"}
}' >/etc/docker/daemon.json

## Check docker.sock
DOCKER_HOST=/var/run/docker.sock
if test -f "$DOCKER_HOST"; then
   export DOCKER_HOST=$DOCKER_HOST
else
   export DOCKER_HOST='tcp://docker:2375'
fi

if docker compose > /dev/null 2>&1; then echo " stage 1 works " ; fi
if docker help  > /dev/null 2>&1; then echo " stage 2 works " ; fi

function domain() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Treafik Domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     DNS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     DNS records will not be automatically added
           with the following TLD Domains
           .a, .cf, .ga, .gq, .ml or .tk
     Cloudflare has limited their API so you
          will have to manually add these
   records yourself via the Cloudflare dashboard.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Which domain would you like to use?: " DOMAIN </dev/tty
   if [[ $DOMAIN == "" ]]; then
      echo "Domain cannot be empty" && domain
   else
      export $DOMAIN && traefik
   fi

}

function displayname() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Username
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your username for Authelia (eg. John Doe): " DISPLAYNAME </dev/tty
   if [[ $DISPLAYNAME == "" ]]; then
      echo "Username cannot be empty" && displayname
   else
      export $DISPLAYNAME && traefik
   fi
}

function password() {
 printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter a password for $USERNAME: " PASSWORD </dev/tty
   if [[ $PASSWORD == "" ]]; then
      echo "Password cannot be empty" && password
   else
      export $PASSWORD && traefik
   fi
}

function cfemail() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Email-Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "What is your CloudFlare Email Address : " EMAIL </dev/tty
   if [[ $EMAIL != "" ]]; then
      export $EMAIL && traefik
   else
      echo "CloudFlare Email Address cannot be empty" && cfemail
   fi
}

function cfkey() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Global-Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "What is your CloudFlare Global Key: " CFGLOBAL </dev/tty
   if [[ $CFGLOBAL != "" ]]; then
      export $CFGLOBAL && traefik
   else
      echo "CloudFlare Global-Key cannot be empty" && cfkey
   fi
}

function cfzoneid() { 
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Zone-ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Whats your CloudFlare Zone ID: " CFZONEID </dev/tty
   if [[ $CFZONEID != "" ]]; then
      export $CFZONEID && traefik
   else
      echo "CloudFlare Zone ID cannot be empty" && cfzoneid
   fi
}

function deploynow() {

## NOTE 
## env schreiben ( basis env )
## Authelia config schreiben
## traefik compose live schreiben / oder nachrangiger compose in wget file
## Authelia Password ? Docker socket mounten? 
## D-o-D system ? 
## shell A Record hinzufügen bei CF ?

SERVERIP=$(curl -s http://whatismijnip.nl | cut -d " " -f 5)
if [[ $SERVERIP == "" ]];then
   SERVERIP=$(curl ifconfig.me) && \
   export $SERVERIP
fi

echo -e "##Environment for Docker-Compose
## TRAEFIK
CLOUDFLARE_EMAIL=${CF-EMAIL}
CLOUDFLARE_API_KEY=${CF-API-KEY}
DOMAIN1_ZONE_ID=${CF-ZONE_ID}
DOMAIN=${DOMAIN}
CLOUDFLARED_UUID=${CLOUDFLARED_UUID:-TUNNEL_UUID_HERE}

## AUTHELIA 
AUTHELIA_USERNAME=${AUTH_USERNAME}
AUTHELIA_PASSWORD=${AUTH_PASSWORD}

## TRAEFIK-ERROR-PAGES
TEMPLATE_NAME=${TEMPLATE_NAME:-l7-dark}

## APPPART
TZ=${TZ}
ID=${ID:-1000}
DOCKERNETWORK=${DOCKERNETWORK:-proxy}
SERVERIP=${SERVERIP:-SERVERIP_ID}
APPFOLDER=${APPFOLDER:-/opt/appdata}
RESTARTAPP=${RESTARTAPP:-unless-stopped}
UMASK=${UMASK:-022}
LOCALTIME=${LOCALTIME:-/etc/localtime}
TP_HOTIO=${TP_HOTIO:-true}
PLEX_CLAIM=${PLEX_CLAIM:-PLEX_CLAIM_ID}

## DOCKERSECURITY
NS1=${NS1:-1.1.1.1}
NS2=${NS2:-8.8.8.8}
PORTBLOCK=${PORTBLOCK:-127.0.0.1}
SOCKET=${SOCKET:-/var/run/docker.sock}
SECURITYOPS=${SECURITYOPS:-no-new-privileges}
SECURITYOPSSET=${SECURITYOPSSET:-true}
##EOF" >/opt/appdata/compose/.env


echo " not done yet but should not token so long"
echo " don't need 18 months , to get it working"

}

function traefik() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Treafik with Authelia over Cloudflare
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [1] Domain                         [ ${DOMAIN} ]
   [2] Authelia Username              [ ${DISPLAYNAME} ]
   [3] Authelia Password              [ ${PASSWORD} ]
   [4] Cloudflare-Email-Address       [ ${CLOUDFLARE_EMAIL} ]
   [5] Cloudflare-Global-Key          [ ${CLOUDFLARE_API_KEY} ]
   [6] Cloudflare-Zone-ID             [ ${DOMAIN1_ZONE_ID} ]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [D] Deploy Treafik with Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [ EXIT or Z ] - Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

   read -erp '↘️  Type Number | Press [ENTER]: ' headtyped </dev/tty
   case $headtyped in
   1) domain ;;
   2) displayname ;;
   3) password ;;
   4) cfemail ;;
   5) cfkey ;;
   6) cfzoneid ;;
   d | D) deploynow ;;
   Z | z | exit | EXIT | Exit | close) exit 0 ;;
   *) clear && traefik ;;
   esac
}



traefik

# E-O-F FUU shitbox

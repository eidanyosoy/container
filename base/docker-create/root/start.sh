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
  apk --quiet --no-cache --no-progress update &>/dev/null && \
    apk --quiet --no-cache --no-progress upgrade &>/dev/null

echo "**** install build packages ****" && \
  apk add -U --update --no-cache \
    bash \
    ca-certificates \
    shadow \
    musl \
    curl \
    jq \
    findutils \
    coreutils \
    bind-tools \
    py3-pip \
    python3-dev \
    libffi-dev \
    openssl-dev \
    gcc \
    libc-dev \
    make \
    tzdata \
    docker &>/dev/null

$(which ln) -s $(which python3) /usr/bin/python &>/dev/null
$(which ln) -s $(which pip3) /usr/bin/pip &>/dev/null

$(which curl) -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
  $(which python) /tmp/get-pip.py \
    --disable-pip-version-check \
      --ignore-installed six \
        "pip==22.0.4" \
        "setuptools==62.0.0" \
        "cryptography==36.0.2" \
        "docker-compose==1.29.2" \
        "jinja-compose==0.0.1" \
        "jinja2==3.1.1" \
        "pyyaml" \
        "tld" &>/dev/null

echo "*** cleanup system ****" && \
  apk del --quiet --clean-protected --no-progress && \
    rm -f /var/cache/apk/* /tmp/get-pip.py

[[ ! -d "/etc/docker" ]] && \
  $(which mkdir) -p "/etc/docker"

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

####### START HERE THE MAIN SETTINGS #######
function domain() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Treafik Domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     DNS records will not be automatically added
           with the following TLD Domains
           .a, .cf, .ga, .gq, .ml or .tk
     Cloudflare has limited their API so you
          will have to manually add these
   records yourself via the Cloudflare dashboard.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Which domain would you like to use?: " DOMAIN </dev/tty
   ##echo $DOMAIN && sleep 20
   if [ ! -z "$(dig +short "$DOMAIN")" ]; then
      echo "$DOMAIN  is valid" && \
        export DOMAINNAME=$DOMAIN && \
          traefik
   else
      echo "Domain cannot be empty" && domain
   fi
}

function displayname() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Username
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your username for Authelia (eg. John Doe): " AUTH_USERNAME </dev/tty

   if test -z "$AUTH_USERNAME";then
      echo "Username cannot be empty" && \
        displayname
   else
      export AUTHUSERNAME=$AUTH_USERNAME && \
        traefik
   fi
}

function password() {
 printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter a password for $AUTH_USERNAME: " AUTH_PASSWORD </dev/tty

   if test -z "$AUTH_PASSWORD";then
      echo "Password cannot be empty" && \
        password
   else
      export AUTHPASSWORD=$AUTH_PASSWORD && \
        traefik
   fi
}

function cfemail() {

printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Email-Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "What is your CloudFlare Email Address : " EMAIL </dev/tty
   regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
   if test -z "$EMAIL"; then
     if [[ $EMAIL =~ $regex ]] ; then
        echo "OK" && \
          export CFEMAIL=$EMAIL && \
            traefik
     else
        echo "CloudFlare Email is not valid" && \
          echo "CloudFlare Email Address cannot be empty" && \
            cfemail
      fi
   else
      echo "CloudFlare Email Address cannot be empty" && \
        cfemail
   fi
}

function cfkey() {
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Global-Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "What is your CloudFlare Global Key: " CFGLOBAL </dev/tty
   if test -z "$CFGLOBAL"; then
      export CFGLOBALKEY=$CFGLOBAL && traefik
   else
      echo "CloudFlare Global-Key cannot be empty" && cfkey
   fi
}

function cfzoneid() { 
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Zone-ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Whats your CloudFlare Zone ID: " CFZONEID </dev/tty
   if test -z "$CFZONEID"; then
      export CFZONEIDENT=$CFZONEID && traefik
   else
      echo "CloudFlare Zone ID cannot be empty" && cfzoneid
   fi
}


function addcfrecord() {

ipv4=$($(which curl) -sX GET -4 https://ifconfig.co)
ipv6=$($(which curl) -sX GET -6 https://ifconfig.co)
checkipv4=$(dig @1.1.1.1 -4 ch txt whoami.cloudflare +short)
checkipv6=$(dig @1.1.1.1 -6 ch txt whoami.cloudflare +short)

   ## GET ZONE ID
   zoneid=$($(which curl) -sX GET "https://api.cloudflare.com/client/v4/zones?name=$EMAIL&status=active" \
       -H "X-Auth-Email: $EMAIL" \
       -H "X-Auth-Key: $CFGLOBAL" \
       -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

   ## GET DNS RECORDID
   dnsrecordid=$($(which curl) -sX GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$DOMAIN" \
       -H "X-Auth-Email: $EMAIL" \
       -H "X-Auth-Key: $CFGLOBAL" \
       -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

## IPv4
   ## PUSH A RECORD FOR IPv4
   $(which curl) -sX PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
       -H "X-Auth-Email: $EMAIL" \
       -H "X-Auth-Key: $CFGLOBAL" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":true}" | jq

## IPv6
   ## PUSH A RECORD FOR IPv6
   $(which curl) -sX PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
       -H "X-Auth-Email: $EMAIL" \
       -H "X-Auth-Key: $CFGLOBAL" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"AAAA\",\"name\":\"$DOMAIN\",\"content\":\"$ipv6\",\"ttl\":auto,\"proxied\":true}" | jq
}

function deploynow() {

## NOTE 
## env schreiben ( basis env )                                              {| done
## Authelia config schreiben                                                {| jinja kann das lösen 
## traefik compose live schreiben / oder nachrangiger compose in wget file  {| jinja-compose wird es lösen für uns
## Authelia Password ? Docker socket mounten?                               {| tcpsocket or socket beides wird klappen
## D-o-D system ?                                                           {| done
## shell A Record hinzufügen bei CF ?                                       {| DONE
## CLOUDFLARE TRUSTED IPS ändert sich immer wieder                          {| done
## Muss also gepullt werden und in Traefik geadded werden                   {| done

## CF TRUSTED IPS LIVE PULL AND MAP
   if test -f "/tmp/trusted_cf_ips"; then $(which rm) -rf /tmp/trusted_cf_ips ; fi
## IPv4 PULL
   for i in `curl -sX GET "https://www.cloudflare.com/ips-v4"`; do echo $i >>/tmp/temp_trustedips ; done
## IPv6 PULL
   for i in `curl -sX GET "https://www.cloudflare.com/ips-v6"`; do echo $i >>/tmp/temp_trustedips ; done

   cat /tmp/temp_trustedips | while IFS=$'\n' read -ra CFTIPS; do echo -ne "${CFTIPS[0]}" >>/tmp/trusted_cf_ips ; done
     if test -f "/tmp/endtrustedips";then $(which rm) -rf /tmp/endtrustedips ; fi

## REMOVE LATEST , TO PREVENT IP FAILS
   cat /tmp/trusted_cf_ips | sed 's/.$//' >/tmp/endtrustedips
     CFTRUSTEDIPS=$($(which cat) /tmp/endtrustedips)

## SERVERIP 
SERVERIP=$($(which curl) -s http://whatismijnip.nl | cut -d " " -f 5)
if [[ "$SERVERIP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
   echo "We found a valid IP | $SERVERIP | success"
else
  echo "First test failed : Running secondary test now."
  if [[ $SERVERIP == "" ]];then
     echo "We found a valid IP | $SERVERIP | success" && \
       SERVERIP=$($(which curl) ifconfig.me) && \
         export SERVERIP=$SERVERIP
  fi
fi

## VALUES FOR DEPLOY REPULL FROM EXPORT
DOCKERHOST=$DOCKER_HOST
DOMAINNAME=$DOMAIN
AUTHUSERNAME=$AUTH_USERNAME
AUTHPASSWORD=$AUTH_PASSWORD
CFEMAIL=$EMAIL
CFGLOBALKEY=$CFGLOBAL
CFZONEIDENT=$CFZONEID
SERVERIPGLOBAL=$SERVERIP

## AUTHELIA TOKENS
JWTTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
SECTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
ENCTOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

## ARGON PASSWORD HASHED
$(which docker) pull authelia/authelia -q >/dev/null
  AUTHPASSWORDSECRET=$($(which docker) run authelia/authelia authelia hash-password $AUTH_PASSWORD -i 2 -k 32 -m 128 -p 8 -l 32 | sed 's/Password hash: //g')
    AUTHELIAPASSWORDSECRET=$AUTH_PASSWORD

## ----

## AUTHELIA CONFIG

## USER CONFIG 
## AUTHELIA CONFIG

## ----

## TRAEFIK CONFIG HIER

# TOMLS / RULES !!

## ENV FILE

TZONE=$($(which timedatectl) | grep "Time zone:" | awk '{print $3}')
CFTRUSTEDIPS=$($(which cat) /tmp/endtrustedips)

echo -e "##Environment for Docker-Compose
## TRAEFIK
CLOUDFLARE_EMAIL=${CFEMAIL}
CLOUDFLARE_API_KEY=${CFGLOBALKEY}
CLOUDFLARE_TRUSTED_IPS=${CFTRUSTEDIPS}
DOMAIN1_ZONE_ID=${CFZONEIDENT}
DOMAIN=${DOMAINNAME}
CLOUDFLARED_UUID=${CLOUDFLARED_UUID:-TUNNEL_UUID_HERE}

## AUTHELIA 
AUTHELIA_USERNAME=${AUTHUSERNAME}
AUTHELIA_PASSWORD=${AUTHPASSWORD}

## TRAEFIK-ERROR-PAGES
TEMPLATE_NAME=${TEMPLATE_NAME:-l7-dark}

## APPPART
TZ=${TZONE}
ID=${ID:-1000}
DOCKERNETWORK=${DOCKERNETWORK:-proxy}
SERVERIP=${SERVERIPGLOBAL}
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
SOCKET=${DOCKERHOST:-/var/run/docker.sock}
SECURITYOPS=${SECURITYOPS:-no-new-privileges}
SECURITYOPSSET=${SECURITYOPSSET:-true}
##EOF" >/opt/appdata/compose/.env

## CLOUDFLARE A RECORD HIER !!!  || DONE
## ERLEICHTERT ALLES FÜR UNS     {| halb fertig
## CF SETTINGS ?!                || muss python werden das bash limits hat
## python oder doch bash ?!      {{ SIEHE LINE DRÜBER 

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
     d | D) addcfrecord && deploynow ;;
     Z | z | exit | EXIT | Exit | close) exit 0 ;;
     *) clear && traefik ;;
   esac
}

traefik
# E-O-F FUU shitbox

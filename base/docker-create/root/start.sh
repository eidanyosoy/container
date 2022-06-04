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
### ECHO PARTS ###
function progress() {
  $(which echo) && \
    $(which echo) -e "\e[1;31m[SETTING : CHECK]\e[0m \e[1m$1\e[0m"
}
function progressinst() {
  $(which echo) && \
    $(which echo) -e "\e[1;32m[INSTALL DEPENDS]\e[0m \e[1m$1\e[0m"
}
function pushlines() {
  $(which echo) && \
    $(which echo) -e "\e[0;33m[RUN NOW]\e[0m \e[1m$1\e[0m"
}
function pushstart() {
  $(which echo) && \
    $(which echo) -e "\e[0;33m[TRAEFIK HEAD INTERFACE]\e[0m \e[1m$1\e[0m"
}

function progressfail() {
  $(which echo) && \
    $(which echo) -e "\e[0;91m[SETTING : FAILED]\e[0m \e[1m$1\e[0m"
}

### INSTALL PARTS ###
function upptsys() {
  $(which apk) --quiet --no-cache --no-progress update &>/dev/null && \
    $(which apk) --quiet --no-cache --no-progress upgrade &>/dev/null
}
function insatpp() {
  $(which apk) add -U --update --no-cache \
    bash ca-certificates shadow musl curl jq \
      findutils coreutils bind-tools py3-pip python3-dev libffi-dev \
        openssl-dev gcc git libc-dev make tzdata docker &>/dev/null
}
function bootstrap() {
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
}

### LINKING AND CLEANUP ###
function linking() {
$(which ln) -s $(which python3) /usr/bin/python &>/dev/null && \
  $(which ln) -s $(which pip3) /usr/bin/pip &>/dev/null
}

function cleanup() {
  $(which apk) del --quiet --clean-protected --no-progress && \
    $(which rm) -f /var/cache/apk/* /tmp/get-pip.py
}

### FUNCTION ENDS ####
## add repositories apk parts
cat > /etc/apk/repositories << EOF; $(echo)
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

progressinst "**** update packages ****" && \
  upptsys && \
progressinst "**** install build packages ****" && \
  instapp && \
progressinst "**** linking dependencies ****" && \
  linking && \
progressinst "**** install python packages ****" && \
  bootstrap && \
progress "*** cleanup system ****" && \
  cleanup

[[ ! -d "/etc/docker" ]] && \
  $(which mkdir) -p "/etc/docker"

$(which echo) '{
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
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
   if [ ! -z "$(dig +short "$DOMAIN")" ]; then
      progress "$DOMAIN  is valid" && \
        export DOMAINNAME=$DOMAIN && \
          traefik
   else
      progressfail "Domain cannot be empty" && domain
   fi
}

function displayname() {
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Username
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   This will be the main user for Authelia
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your username for Authelia (eg. John Doe): " AUTH_USERNAME </dev/tty
   if test -z "$AUTH_USERNAME";then
      progressfail "*** Username cannot be empty ***" && \
        displayname
   else
      progress "**** AUTHELIA USER IS SET ****" && \
        export AUTHUSERNAME=$AUTH_USERNAME && \
          traefik
   fi
}

function password() {
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Authelia Password
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   This will be the password for ${AUTH_USERNAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter a password for $AUTH_USERNAME: " AUTH_PASSWORD </dev/tty
   if test -z "$AUTH_PASSWORD";then
      progressfail "*** Password cannot be empty ***" && \
        password
   else
      progress "*** AUTHELIA Password is set ***" && \
        export AUTHPASSWORD=$AUTH_PASSWORD && \
          traefik
   fi
}

function cfemail() {
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Email-Address
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Cloudflare Login Email
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your CloudFlare Email Address : " EMAIL </dev/tty
   regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
   if ! test -z "$EMAIL"; then
      if [[ $EMAIL =~ $regex ]] ; then
         progress "*** Cloudflare EMail is set ***" && \
           export CFEMAIL=$EMAIL && \
             traefik
      else
         progressfail "*** CloudFlare Email is not valid ***" && \
           cfemail
      fi
   else
      progressfail "*** CloudFlare Email Address cannot be empty ***" && \
        cfemail
   fi
}

function cfkey() {
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Global-Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Cloudflare || https://dash.cloudflare.com/

  Scroll down to API or use || https://dash.cloudflare.com/profile/api-tokens

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your CloudFlare Global Key: " CFGLOBAL </dev/tty
   if ! test -z "$CFGLOBAL"; then
      progress "*** CloudFlare Global Key is set ***" && \
        export CFGLOBALKEY=$CFGLOBAL && \
          traefik
   else
      progressfail "*** CloudFlare Global-Key cannot be empty ***" && cfkey
   fi
}

function cfzoneid() { 
pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Cloudflare Zone-ID
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Cloudflare || https://dash.cloudflare.com/

  Scroll down to Cloudflare Zone ID

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   read -erp "Enter your CloudFlare Zone ID: " CFZONEID </dev/tty
   if ! test -z "$CFZONEID"; then
      progress "*** CloudFlare Zone ID is set ***" && \
        export CFZONEIDENT=$CFZONEID && \
          traefik
   else
      progressfail "CloudFlare Zone ID cannot be empty" && cfzoneid
   fi
}


function addcfrecord() {

ipv4=$($(which curl) -sX GET -4 https://ifconfig.co)
ipv6=$($(which curl) -sX GET -6 https://ifconfig.co)
checkipv4=$(dig @1.1.1.1 -4 ch txt whoami.cloudflare +short)
checkipv6=$(dig @1.1.1.1 -6 ch txt whoami.cloudflare +short)

pushlines "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀  ADDING NOW CLOUDFLARE RECORDS NOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
## Authelia config schreiben                                                {| done 
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

   $(which cat) /tmp/temp_trustedips | while IFS=$'\n' read -ra CFTIPS; do
    $(which echo) -ne "${CFTIPS[0]}" >>/tmp/trusted_cf_ips
   done
     if test -f "/tmp/endtrustedips";then $(which rm) -rf /tmp/endtrustedips ; fi

## REMOVE LATEST , TO PREVENT IP FAILS
   $(which cat) /tmp/trusted_cf_ips | sed 's/.$//' >/tmp/endtrustedips
     CFTRUSTEDIPS=$($(which cat) /tmp/endtrustedips)

## SERVERIP 
SERVERIP=$($(which curl) -s http://whatismijnip.nl | cut -d " " -f 5)
if [[ "$SERVERIP" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
   progress "*** We found a valid IP | $SERVERIP | success ***"
else
  progressfail "*** First test failed : Running secondary test now. ***"
  if [[ $SERVERIP == "" ]];then
     progress "*** We found a valid IP | $SERVERIP | success ***" && \
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

## AUTHELIA USER CONFIG
source /templates/authelia/users_database.yml
  $(which cat) /templates/authelia/users_database.yml > /opt/appdata/authelia/users_database.yml
## AUTHELIA CONFIG
source /templates/authelia/configuration.yml
  $(which cat) /templates/authelia/configuration.yml > /opt/appdata/authelia/configuration.yml

## TRAEFIK CONFIG HIER
$(which cp) -r /templates/traefik/rules/middlewares.toml /opt/appdata/traefik/rules/middlewares.toml
$(which echo) -e '
  [http.middlewares.middlewares-authelia]
    [http.middlewares.middlewares-authelia.forwardAuth]
      address = "'http://authelia:9091/api/verify?rd=https://authelia.${DOMAIN}'"
      trustForwardHeader = true
      authResponseHeaders = ["'Remote-User'", "'Remote-Groups'"]
' >> /opt/appdata/traefik/rules/middlewares.toml

## ENV FILE
TZONE=$($(which timedatectl) | grep "Time zone:" | awk '{print $3}')
CFTRUSTEDIPS=$($(which cat) /tmp/endtrustedips)

$(which echo) -e '##Environment for Docker-Compose

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
##EOF' >/opt/appdata/compose/.env

## CLOUDFLARE A RECORD HIER !!!  || DONE
## ERLEICHTERT ALLES FÜR UNS     {| halb fertig
## CF SETTINGS ?!                || muss python werden das bash limits hat
## python oder doch bash ?!      {{ SIEHE LINE DRÜBER 

}

function traefik() {
pushstart "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚀   Treafik with Authelia over Cloudflare
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [1] Domain                     =  ${DOMAIN}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [2] Authelia Username          =  ${AUTHUSERNAME}
   [3] Authelia Password          =  ${AUTH_PASSWORD}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [4] Cloudflare Email Address   =  ${CFEMAIL}
   [5] Cloudflare Global Key      =  ${CFGLOBALKEY}
   [6] Cloudflare Zone ID         =  ${CFZONEIDENT}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [D] Create all configs for Treafik and Authelia
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

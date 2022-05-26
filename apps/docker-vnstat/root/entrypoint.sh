#!/bin/bash

apt update -y && apt upgrade -y && \
apt install curl bash wget git yarn curl

cd /home && 
   wget https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_18.x -o nodesource_setup.sh
   bash nodesource_setup.sh

## RUN NODE INSTALL 
   apt install curl wget git yarn curl nodejs

#### CLONE REPOSITORIE ####

cd .. && git clone https://github.com/Hulxv/vnstat-client.git

#### RUN INSTALL ####
cd ./vnstat-client
   yarn --frozen-lockfile
   yarn install
   yarn build


NEWVERSION=$(curl -sX GET "https://api.github.com/repos/Hulxv/vnstat-client/releases/latest" | jq -r '. | .tag_name')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION}"

#### CLONE REPOSITORIE ####

#### ECHO VERSION FOR EXECUTE ####
echo "${NEWVERSION} vnstat-client"

cd ./dist && \
   vnstat-client-${NEWVERSION}.AppImage



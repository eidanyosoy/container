#!/bin/bash
NEWVERSION=$(curl -sX GET "https://api.github.com/repos/Hulxv/vnstat-client/releases/latest" | jq -r '. | .tag_name')
NEWVERSION="${NEWVERSION#*v}"
NEWVERSION="${NEWVERSION}"

#### CLONE REPOSITORIE ####
git clone --quiet https://github.com/Hulxv/vnstat-client.git

#### RUN INSTALL ####
cd ./vnstat-client && \
   yarn --frozen-lockfile && \
   yarn install && \
   yarn build

#### ECHO VERSION FOR EXECUTE ####
echo "${NEWVERSION} vnstat-client"

cd ./dist && \
./vnstat-client-${NEWVERSION}.AppImage

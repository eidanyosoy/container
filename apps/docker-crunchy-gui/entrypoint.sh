#!/bin/bash

apk add nodejs npm git ffmpeg xsel mkvtoolnix

git clone https://github.com/anidl/multi-downloader-nx.git /app

cd /app

npm update --save

npm i -g npm-check-updates && ncu -u

npm i -g ts-node serve && npm i 

npm run tsc true

serve -s build

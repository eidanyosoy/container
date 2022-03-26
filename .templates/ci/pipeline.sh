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

## APT/APK
if command -v apk &>/dev/null; then
   apk info -v | sort >/tmp/package.txt
elif command -v apt &>/dev/null; then
   apt list -qq --installed | sed "s#/.*now #=#g" | cut -d" " -f1 | sort >/tmp/package.txt
fi

## PIP
if command -v pip3 &>/dev/null; then
   pip3 freeze | sort >/tmp/pip_package.txt
elif command -v pip &>/dev/null; then
   pip freeze | sort >/tmp/pip_package.txt
fi

## YARN
if command -v yarn &>/dev/null; then
   mkdir -p /home && \
   yarn list --depth=0 | awk '{print $2}' | sort >/home/yarn_package.txt && \
   rm -rf /tmp/v8-compile-**
   cp /home/yarn_package.txt /tmp/yarn_package.txt
fi

## NPM
if command -v npm &>/dev/null; then
   mkdir -p /home && \
   npm list --depth=0 | awk '{print $2}' | sort >/home/npm_package.txt && \
   rm -rf /tmp/v8-compile-** && \
   cp /home/npm_package.txt /tmp/npm_package.txt
fi

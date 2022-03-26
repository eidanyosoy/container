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
# shellcheck disable=SC204

#!/usr/bin/env bash

# Bash unofficial strict mode
set -euo pipefail
IFS=$'\n\t'
LANG=''

function define() { IFS='\n' read -r -d '' ${1} || true; }

define TMPL << 'EOF'
{
  "message": "MSG",
  "verification_flag": "%G?",
  "author": {
    "name": "AUTHOR",
    "date": "%ai"
  },
  "commiter": {
    "name": "COMMITER",
    "date": "%ci"
  }
}
EOF

function sanitize () {
  # strip newlines, strip all whitespace, escape newline
  sed -E -e ':a' -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' -e 's/^\s+|\s+$//g' -e ':a;N;$!ba;s/\n/\\n/g' \
    | sed -E -e 's/%/%%/g' -e 's/"/\\"/g' -e 's/\\\\/\\/g' -e 's/\t/\\t/g' -e 's/\\([^nt"])/\\\\\1/g' -e 's/[\x00-\x1f]//g' | tr -d '\r\0\t'
  # escape percent sign for template, escape quotes, escape backslash, escape tabs, fix double escapes, delete control characters
}

function field () {
  git show -s --format="$1" "$2" | sanitize
}

git log --pretty=format:'%H' | while IFS='' read -r hash; do
  TMP="$TMPL"
  msg=$(field "%B" $hash)
  author=$(field "%aN" $hash)
  commiter=$(field "%cN" $hash)
  TMP="${TMP/MSG/$msg}"
  TMP="${TMP/AUTHOR/$author}"
  TMP="${TMP/COMMITER/$commiter}"
  git show $hash -s --format="$TMP"
done

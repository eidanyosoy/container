#!/usr/bin/env bash
version="$(curl -u $username:$token -X GET "https://api.github.com/repos/theotherp/nzbhydra2/releases" | jq --raw-output '.[0].tag_name')"
version="${version#*v}"
version="${version#*release-}"
printf "%s" "${version}"

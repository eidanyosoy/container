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

folder=$(ls -1p ./ | grep '/$' | sed 's/\/$//' | sed '/images/d' | sed '/dead/d' )

for i in ${folder[@]}; do
   find ./$i -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort | while read app; do
      if test -f "./.templates/ci/packages.sh"; then
         if [[ "${app}" != "docker-cloudflared" ]];then
            echo "$i" "${app}" && \
            docker run --rm \
               --name CI-RUN-${app} \
               --entrypoint /bin/sh \
               -v ${PWD}/$i/${app}:/tmp \
               -v ${PWD}/.templates/ci/pipeline.sh:/pipeline.sh \
               ghcr.io/dockserver/${app}:latest -c 'apk add --quiet bash || apt install bash -yqq && chmod -cR 755 /pipeline.sh && bash /pipeline.sh'
               docker stop CI-RUN-${app} && docker rmi CI-RUN-${app}
          fi
       fi
   done
done

sleep 5
if [[ -n $(git status --porcelain) ]]; then
   git config --global user.name 'github-actions[bot]'
   git config --global user.email 'github-actions[bot]@users.noreply.github.com'
   git add -A
   git commit -sam "[Auto Update Depends] Get New Package Versions From Image" || true
   git push --force
fi

exit 0

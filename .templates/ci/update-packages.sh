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

export username=${username}
export token=${token}

## RUN PACKAGES
folder=$(ls -1p ./ | grep '/$' | sed 's/\/$//' | sed '/wiki/d' | sed '/dead/d' | sed '/images/d' )
for i in ${folder[@]}; do
   find ./$i -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | while read app; do
      if test -f "./.templates/ci/packages.sh"; then
         if [[ "${app}" != "docker-cloudflared" ]];then
            echo "$i" "${app}" && \
            docker run --rm \
               --name CI-RUN-${app} \
               --entrypoint /bin/sh \
               -v ${PWD}/$i/${app}:/tmp \
               -v ${PWD}/.templates/ci/pipeline.sh:/pipeline.sh \
               ghcr.io/dockserver/${app}:latest -c 'apk add --quiet bash || apt install bash -yqq && chmod -cR 755 /pipeline.sh && bash /pipeline.sh'
               docker system prune -af || true
         fi
       fi
   done
done

#### END FILE ####

sleep 5
if [[ -n $(git status --porcelain) ]]; then
   git config --global user.name 'github-actions[bot]'
   git config --global user.email 'github-actions[bot]@users.noreply.github.com'
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git repack -adf --depth=5000 --window=5000
   git add -A
   COMMIT=$(git show -s --format="%H" HEAD)
   LOG=$(git diff-tree --no-commit-id --name-only -r $COMMIT)
   git commit -sam "[Auto Changes Packages] Changes : $LOG" || exit 0
   git push --force
fi

exit 0

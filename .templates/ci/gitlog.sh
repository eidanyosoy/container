#!/bin/bash

# Generates git log grouped by day and outputs to markdown file
#
# optional parameters
# -a, --author       to filter by author
# -s, --since        to select start date
# -u, --until        to select end date

git-log-to-markdown () {
  local NEXT=$(date +%F)

  local RED="\x1B[31m"
  local YELLOW="\x1B[32m"
  local BLUE="\x1B[34m"
  local RESET="\x1B[0m"

  local SINCE="1970-01-01"
  local UNTIL=$NEXT


  for i in "$@"
  do
  case $i in
    -a=*|--author=*)
    local AUTHOR="${i#*=}"
    shift
    ;;
    -s=*|--since=*)
    SINCE="${i#*=}"
    shift
    ;;
    -u=*|--until=*)
    UNTIL="${i#*=}"
    shift
    ;;
    *)
      # unknown option
    ;;
  esac
  done

  local LOG_FORMAT=" %Cgreen*%Creset %s"
  
  if [ -z "$AUTHOR" ]
  then
    LOG_FORMAT="$LOG_FORMAT %Cblue(%an)%Creset"
  else
    echo "# Container GitLog"
  fi

  git log --no-merges --author="${AUTHOR}" --since="${SINCE}" --until="${UNTIL}" --format="%cd" --date=short | sort -u | while read DATE ; do

    local GIT_PAGER=$(git log --no-merges --reverse --format="${LOG_FORMAT}" --since="${DATE} 00:00:00" --until="${DATE} 23:59:59" --author="${AUTHOR}")

    if [ ! -z "$GIT_PAGER" ]
    then
      echo
      echo -e "## $DATE"
      echo -e "${GIT_PAGER}"
    fi

  done

}

if test -f "./wiki/docs/install/container-gitlog.md"; then
   rm -f "./wiki/docs/install/container-gitlog.md" && \
   cat "./wiki/docs/install/headline.md" > ./wiki/docs/install/container-gitlog.md
   git-log-to-markdown "$@" > ./wiki/docs/install/container-gitlog.md
fi

sleep 5
if [[ -n $(git status --porcelain) ]]; then
   git config --global user.name 'dockserver-bot[bot]'
   git config --global user.email 'dockserver-bot[bot]@dockserver.io'
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git repack -adf --depth=5000 --window=5000
   git add -A
   COMMIT=$(git show -s --format="%H" HEAD)
   LOG=$(git diff-tree --no-commit-id --name-only -r $COMMIT)
   git commit -sam "[Auto Generation] Changelog : $LOG" || exit 0
   git push --force
fi

exit 0

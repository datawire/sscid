#!/usr/bin/env bash
set -eEux

function post_to_slack () {
  # format message as a code block ```${msg}```
  SLACK_MESSAGE="\`\`\`$1\`\`\`"
  SLACK_URL=https://hooks.slack.com/services/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
 
  case "$2" in
    INFO)
      SLACK_ICON=':slack:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':bangbang:'
      ;;
    *)
      SLACK_ICON=':slack:'
      ;;
  esac
 
  curl -X POST --data "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}
}

# Project config
PROJECT_NAME="datawire/telepresence"
GIT_URL="https://github.com/${PROJECT_NAME}.git"

BRANCH=ci-mac
SCRIPT=build-macosx.sh

# SSCID config and setup
SSCID_WORKSPACE=${HOME}/sscid
PROJECT_WORKSPACE=${SSCID_WORKSPACE}/${PROJECT_NAME}

# Clean up leftover Telepresence test junk
rm -rf $HOME/tpbin

cleanup() {
  printf "Performing cleanup...\n"
  post_to_slack "Uh oh, Mac OS X build of Telepresence failed!" "WARNING"
#  rm -rf ${PROJECT_WORKSPACE}/latest
}

trap cleanup ERR

mkdir -p ${PROJECT_WORKSPACE}
cd ${PROJECT_WORKSPACE}

if [ -d "./latest" ]; then
  printf "Run in progress; Not continuing\n"
  exit 0
fi

git clone ${GIT_URL} latest

cd latest
chmod -R 0755 .git
git checkout ${BRANCH}
GIT_COMMIT=$(git rev-parse HEAD)

# execute the build script and shit the output to a file
set +exE
./${SCRIPT} > sscid.log 2>&1
echo "$?" > sscid.result
set -eE

mkdir -p ${PROJECT_WORKSPACE}/${GIT_COMMIT}
cp -R  ${PROJECT_WORKSPACE}/latest/* ${PROJECT_WORKSPACE}/${GIT_COMMIT}
# rm -rf ${PROJECT_WORKSPACE}/latest

# Upload log to S3

cd ${PROJECT_WORKSPACE}
aws s3 sync ${SSCID_WORKSPACE} s3://sscid \
    --exclude "*" \
    --include "*/sscid.result" \
    --include "*/sscid.log"



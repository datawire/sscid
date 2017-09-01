#!/usr/bin/env bash
set -eEuo pipefail

# Project config
PROJECT_NAME="datawire/telepresence"
GIT_URL="https://github.com/${PROJECT_NAME}.git"

BRANCH=dev/macos-sscid
SCRIPT=ci/macos-sscid.sh

# SSCID config and setup
SSCID_WORKSPACE=${HOME}/sscid
PROJECT_WORKSPACE=${SSCID_WORKSPACE}/${PROJECT_NAME}

cleanup() {
  printf "Performing cleanup...\n"
  rm -rf ${PROJECT_WORKSPACE}/latest
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
set +ex
./${SCRIPT} > sscid.log
echo "$?" > sscid.result
set -e

mkdir -p ${PROJECT_WORKSPACE}/${GIT_COMMIT}
cp -R  ${PROJECT_WORKSPACE}/latest/* ${PROJECT_WORKSPACE}/${GIT_COMMIT}
rm -rf ${PROJECT_WORKSPACE}/latest

# Upload log to S3

cd ${PROJECT_WORKSPACE}
aws s3 sync ${SSCID_WORKSPACE} s3://sscid \
    --exclude "*" \
    --include "*/sscid.result" \
    --include "*/sscid.log"



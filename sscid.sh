#!/usr/bin/env bash
set -euxo pipefail

# Project config
PROJECT_NAME="datawire/sscid"
GIT_URL="https://github.com/${PROJECT_NAME}.git"

BRANCH=master
SCRIPT=test.sh

# SSCID config and setup
SSCID_WORKSPACE=${HOME}/sscid
PROJECT_WORKSPACE=${SSCID_WORKSPACE}/${PROJECT_NAME}

mkdir -p ${PROJECT_WORKSPACE}/results
cd ${PROJECT_WORKSPACE}

if [ -d "./latest" ]; then
  printf "Run in progress; Not continuing"
  exit 0
fi

git clone ${GIT_URL} latest

cd latest
git checkout ${BRANCH}
GIT_COMMIT=$(git rev-parse HEAD)

# execute the build script and shit the output to a file
set +e
./${SCRIPT} > sscid.log
set -e

echo "$?" > sscid.result

cp -R . ${PROJECT_WORKSPACE}/${GIT_COMMIT}
rm -rf ${PROJECT_WORKSPACE}/latest

# Upload log to S3

cd ${PROJECT_WORKSPACE}
aws s3 sync . s3://sscid --exclude "*latest/*" --include "*/sscid.result" --include "*/sscid.log"


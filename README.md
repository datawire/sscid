# Stupid Simple CI Server

For running CI tests on our local macOS laptop because Travis CI is too slow for macOS.

## Setup

SSCID requires Python 3 so make sure Python 3 is installed then:

```bash
pip3 install -U git+git://github.com/datawire/scout2csv.git
```

## Start the SSCID server...

```bash
sscid
```

## Forward Ngrok domain to it

```bash
ngrok http -subdomain=sscid-macos localhost:5000
```

## API

### POST /build

Starts a new build and test run. The POST body should include enough information to clone the Git repository and checkout the code:

The body has the following format:

```json
{
  "repo_slug": "string",
  "branch": "string",
  "commit": "string",
  "is_pull_request": "boolean",
  "build_script": "string"
}
```

For example, to test commit `ea2d011158ce3f690322870db87b5b8639ecb1a6` on `master` of the `datawire/sscid` repository the payload below would be sent:

```json
{
  "repo_slug": "datawire/sscid",
  "branch": "master",
  "commit": "ea2d011158ce3f690322870db87b5b8639ecb1a6",
  "is_pull_request": false,
  "build_script": "test.sh"
}
```

## Using from Travis

Set the Travis Ngrok URL to a secure environment variable with:

`$> travis env set SSCID_HOST <value>`

The easiest way to invoke SSCID from Travis is to send an HTTP POST with `curl`. The below script can help accomplish this. Update the `build_script` path to point to correct file. Leave `is_pull_request` as `false` for the time being:

```
$> cat << EOF > /tmp/sscid-build.json
{
  "repo_slug": "${TRAVIS_REPO_SLUG}",
  "branch": "${TRAVIS_BRANCH}",
  "commit": "${TRAVIS_COMMIT}",
  "is_pull_request": false,
  "build_script": "test.sh"
}
EOF

$> curl -v -X POST -H 'Content-Type: application/json' -d '@/tmp/sscid-build.json' ${SSCID_HOST}/build
```

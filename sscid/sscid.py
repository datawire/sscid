#!/usr/bin/env python

import datetime
import logging
import subprocess
import sys
import threading
import boto3

from flask import Flask, request, jsonify
from git import Repo
from pathlib import Path


sscid_workspace = ws_root = Path.home() / "sscid"
sscid_workspace.mkdir(parents=True, exist_ok=True)

app = Flask(__name__)
app.logger.addHandler(logging.StreamHandler(sys.stdout))
app.logger.setLevel(logging.DEBUG)

s3 = boto3.client("s3")


def run(on_exit_fn, *args, **kwargs):

    """
    Runs a subprocess.Popen and then calls on_exit_fn when the subprocess completes.

    Use it exactly the way you would normally use subprocess.Popen, except include a callable to execute as the first
    argument. on_exit_fn is a callable object, and *args and **kwargs are simply passed up to subprocess.Popen.
    """
    def run_in_thread(on_exit, popen_args, popen_kwargs):
        proc = subprocess.Popen(*popen_args, **popen_kwargs)
        result_code = proc.wait()
        on_exit(result_code, popen_kwargs.get("cwd"))
        return

    thread = threading.Thread(target=run_in_thread, args=(on_exit_fn, args, kwargs))
    thread.start()

    return thread


def create_build_workspace(repo_slug, branch, commit, timestamp):
    commit_info = "{}_{}_{}".format(branch.replace("/", "-"), commit, timestamp.strftime("%Y%m%d%H%M%S"))
    build_workspace = sscid_workspace / "{}_{}".format(repo_slug, commit_info).replace("/", "-")
    build_workspace.mkdir(parents=True, exist_ok=True)

    return build_workspace


@app.route("/status", methods=["GET"])
def status():
    pass


@app.route("/build", methods=["POST"])
def build():
    payload = request.json

    repo_slug = payload.get("repo_slug")
    branch = payload.get("branch")
    commit = payload.get("commit")
    is_pull_request = bool(payload.get("is_pull_request"))
    build_script = payload.get("build_script")
    build_cmd = payload.get("build_cmd")  # reserved for the future; would be a JSON array of args

    app.logger.info("Build started => {} {}@{}".format(repo_slug, branch, commit))

    if is_pull_request:
        return jsonify(error="BUILD_IS_PULL_REQUEST"), 400

    build_ws = create_build_workspace(repo_slug, branch, commit, datetime.datetime.now())
    cloned = Repo.clone_from("https://github.com/{}.git".format(repo_slug), str(build_ws))
    git = cloned.git
    git.checkout(commit)

    if not (build_ws / build_script).is_file():
        return jsonify(error="BUILD_SCRIPT_NOT_FOUND"), 400

    sscid_outputs = build_ws / ".sscid"
    sscid_outputs.mkdir(parents=True, exist_ok=True)

    build_output = build_ws / ".sscid" / "build.out"

    with build_output.open("wb+") as out:
        run(on_build_finished,
            str(build_ws / build_script),
            cwd=str(build_ws),
            stdout=out,
            stderr=subprocess.STDOUT)

    return "", 204


def on_build_finished(return_code, cwd):
    import os
    from os.path import normpath, basename

    app.logger.info("Build finished => {}".format(return_code))
    s3_key_base = basename(normpath(cwd))

    for root, dirs, files in os.walk(os.path.join(cwd, ".sscid")):
        for filename in files:
            local_path = os.path.join(root, filename)

            relative_path = os.path.relpath(local_path, cwd)
            s3_path = os.path.join(s3_key_base, filename)

            print("Uploading => {}".format(local_path))
            s3.upload_file(local_path, "sscid", s3_path)


@app.route("/health", methods=["GET", "HEAD"])
def health():
    return "OK", 200


def main():
    import sys

    port = 5000
    if len(sys.argv[1:]) >= 1:
        port = int(sys.argv[1])

    app.run(debug=False, port=port)


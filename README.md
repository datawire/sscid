# Stupid Simple CI Daemon

For running CI tests on our local macOS laptop.

# Setup!

1. Ensure the AWS CLI is installed: `pip install awscli` and that AWS credentials are installed for S3 upload.
2. Install the script somewhere

    ```bash
    $> curl https://raw.githubusercontent.com/datawire/sscid/master/sscid.sh
    $> chmod +x sscid.sh
    ```

3. Configure the project by opening it with a text editor. Find `PROJECT_NAME="datawire/sscid"` and change the `datawire/sscid` part as necessary.
4. Configure the build/test script to run by editing the `SCRIPT=test.sh` variable to point at whatever script you want to run that does the work. Make sure this script exists the project repository of the project you're testing.
5. Tweak the `BRANCH=` variable if you want something other than `master` 
6. Install it as a cron job that runs every minute (use `crontab -e` to launch the cron editor)
    
    `* * * * * /path/to/sscid.sh > /path/to/sscid.log 2>&1`

# Output

Execution output is stored in S3 ... s3://sscid/$GH_SLUG/$GIT_COMMIT_HASH


    


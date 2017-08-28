# Stupid Simple CI Daemon

For running CI tests on our local macOS laptop.

# Setup!

1. Install the script somewhere

    ```bash
    $> curl https://raw.githubusercontent.com/datawire/sscid/master/sscid.sh
    $> chmod +x sscid.sh
    ```

2. Configure the project by opening it with a text editor. Find `PROJECT_NAME="datawire/sscid"` and change the `datawire/sscid` part as necessary.
3. Configure the build/test script to run by editing the `SCRIPT=test.sh` variable to point at whatever script you want to run that does the work. Make sure this script exists the project repository of the project you're testing.
4. Install it as a cron job that runs every minute (use `crontab -e` to launch the cron editor)
    
    `* * * * * /path/to/sscid.sh`

# Output

Execution output is stored in S3 ... s3://sscid/$GH_SLUG/$GIT_COMMIT


    


#!/bin/sh

# ssh related settings for 1 or more servers
# each server will use the same ssh port and user. 
SSH=/usr/bin/ssh
SSH_PORT=22
SSH_USER=www
SSH_HOSTS=(ssh.host1.com ssh.host2.com)

# rsync path
RSYNC=/usr/bin/rsync

# shared dirs will be linked to a shared directory
# SHARED_DIRS=(log tmp files/shared)
SHARED_DIRS=()

# your project directory
LOCAL_DIR=/path/to/your/project

# pac hooks directory which contains "app.sh" and "deploy.sh".
HOOKS_DIR=$LOCAL_DIR/.pac/hooks

# files list here will be ignored when deploy
RSYNC_EXCLUDE_FILE=$HOOKS_DIR/rsync_exclude

# where to deploy your app?
REMOTE_DIR=/opt/srv/yourapp

# number of latest releases to keep
LIMIT_RELEASES=3


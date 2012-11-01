#!/bin/sh
SSH=/usr/bin/ssh
SSH_PORT=22
SSH_USER=www
SSH_HOSTS=(192.168.1.33)

RSYNC=/usr/bin/rsync

SHARED_DIRS=(log tmp public/system)

LOCAL_DIR=/home/me/rails/blog
HOOKS_DIR=/path/to/here/hooks
REMOTE_DIR=/opt/srv/rails-blog
LIMIT_RELEASES=3

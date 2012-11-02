#!/bin/bash

# cap.reverse :-) #
VERSION="0.0.1"

if [[ $1 = "version" || $1 = "-v" || $1 = "--version" ]]; then
    echo "pac version: ${VERSION}"
    exit 0
fi

# initialize
if [[ $1 = "init" ]]; then
    PROJECT_DIR='.'
    if [[ $2 != "" ]]; then
        PROJECT_DIR=$2
    fi
    PAC_DIR="${PROJECT_DIR}/.pac"
    mkdir -p $PAC_DIR 
    mkdir -p $PAC_DIR/hooks
    PAC_CONFIG_FILE="${PAC_DIR}/config.sh"
    if [[ ! -f $PAC_CONFIG_FILE ]]; then
    echo "#!/bin/sh

# ssh related settings for 1 or more servers
# each server will use the same ssh port and user. 
SSH=`which ssh`
SSH_PORT=22
SSH_USER=www
SSH_HOSTS=(ssh.host1.com ssh.host2.com)

# rsync path
RSYNC=`which rsync`

# shared dirs will be linked to a shared directory
# SHARED_DIRS=(log tmp files/shared)
SHARED_DIRS=()

# your project directory
LOCAL_DIR=`realpath ${PROJECT_DIR}`

# pac hooks directory which contains \"app.sh\" and \"deploy.sh\".
HOOKS_DIR=\$LOCAL_DIR/.pac/hooks

# files list here will be ignored when deploy
RSYNC_EXCLUDE_FILE=\$HOOKS_DIR/rsync_exclude

# where to deploy your app?
REMOTE_DIR=/opt/srv/yourapp

# number of latest releases to keep
LIMIT_RELEASES=3
" > $PAC_CONFIG_FILE
    fi
    if [[ ! -f "$PAC_DIR/hooks/rsync_exclude" ]]; then
        echo "*.swp
*.log
*.git/
*.svn/
CVS/
RCS/
SCCS/
.cvsignore
.arch-ids/
.hg
.hgignore
.hgrags
.bzr
.bzrignore
.bzrtags
_darcs
*~
" > "$PAC_DIR/hooks/rsync_exclude"
    fi
    echo "pac initialize has been done."
    echo "The pac directory \".pac\" and some related files has been created."
    echo "You can go and change the files in the directory before you get started."
    echo ""
    exit 0
fi

if [[ $PACFILE = "" ]]; then
    PACFILE=".pac/config.sh"
fi

# load configurations
if [[ -f $PACFILE ]]; then
    . $PACFILE
else
    echo "pac: pac is a simple deployment tool with rsync and ssh, no scm tools required."
    echo "--------------------------------------------------------"
    echo "Notice: It seems that the PACFILE \"${PACFILE}\" doesn't exists."
    echo "Run \"PACFILE=/path/to/your/project/config.sh ${0} -h\" to see more options."
    echo "To initialize the pac settings, please run \"${0} init /path/to/your/project/dir\""
    echo ""
    exit 1 
fi

RSYNC_OPTS=(-avzP --rsh="ssh -p ${SSH_PORT}")
SSH_OPTS="-p ${SSH_PORT}"
RELEASE_DIR=$REMOTE_DIR/releases
SHARED_DIR=$REMOTE_DIR/shared
CURRENT_RELEASE=$RELEASE_DIR/$(date +%Y%m%d%H%M%S)
CURRENT_RELEASE_LINK=$REMOTE_DIR/current

SSH_CMD="${SSH} ${SSH_OPTS} ${SSH_USER}"

function quit {
    log "Something went wrong, exiting ..."
    exit 1
}

function remote_cmd {
    local cmd=$1

    for host in "${SSH_HOSTS[@]}"; do
        log "! Remote exec [${host}]: ${cmd}"
        $SSH_CMD@$host $cmd 
        if [[ $? != 0 ]]; then
            quit
        fi
    done
}

function run_rsync {
    local action=$1

    for host in "${SSH_HOSTS[@]}"; do
        if [[ $action = "deploy" ]]; then
            echo "! Sync from \"${LOCAL_DIR}/\" to \"${SSH_USER}@${host}:${SHARED_DIR}/cached-copy/\" with options \"${RSYNC_OPTS[@]}\" ..."
            $RSYNC "${RSYNC_OPTS[@]}" --delete --exclude-from=$RSYNC_EXCLUDE_FILE $LOCAL_DIR/ $SSH_USER@$host:$SHARED_DIR/cached-copy/
        fi
        if [[ $? != 0 ]]; then
            quit
        fi
    done
}

function log {
    echo -e $1
}

function run_hook {
    local func=$1
    type $func 2>/dev/null | grep 'function' > /dev/null 2>&1 && $func
}

function clean_old_releases {
    log "\n-----------------------------"
    log "\n>> Clean old releases ...\n"
    for host in "${SSH_HOSTS[@]}"; do
        files=`${SSH_CMD}@${host} "cd ${RELEASE_DIR} && ls | sort"`
        read -a array <<< $files 
        length=`expr "${#array[@]}" - ${LIMIT_RELEASES}`

        for (( i = 0; i < ${length}; i++ ))
        do
            cmd="rm -rf ${RELEASE_DIR}/${array[$i]}"
            echo "! Remote exec [${host}]: ${cmd}"
            $SSH_CMD@$host $cmd 
        done
    done
}

START_TIME=$(date +%s)

# deploy it
if [[ $1 = "deploy" ]]; then
    [[ -f $HOOKS_DIR/deploy.sh ]] && . $HOOKS_DIR/deploy.sh
    if [[ $2 = "setup" ]]; then
        log ">> Deployment setup ..."

        # join the array with ","

        ORIGIN_IFS=$IFS
        IFS=","
        MY_SHARED_DIRS="${SHARED_DIRS[*]},cached-copy"
        IFS=$ORIGIN_IFS

        remote_cmd "/bin/mkdir -p ${SHARED_DIR}/{${MY_SHARED_DIRS}} ${RELEASE_DIR}"
    else
        if [[ $2 != "run" ]]; then
            RSYNC_OPTS+=(--dry-run)
            RUN="N"
            log ">> Prepare for deploying ..."
        else
            RUN="Y"
            log ">> Deploying ..."
        fi
        # deploying ...
        if [[ $RUN = "Y" ]]; then
            run_hook "before_deploy"
        fi

        if [[ $2 = "backto" ]]; then
            RUN="Y"
            CURRENT_RELEASE=$RELEASE_DIR/$3
        else
            run_rsync "deploy"
            if [[ $RUN = "Y" ]]; then
                remote_cmd "/bin/cp -r -p ${SHARED_DIR}/cached-copy ${CURRENT_RELEASE}"
            fi
        fi

        # after the real deployment
        if [[ $RUN = "Y" ]]; then
            for dirlink in "${SHARED_DIRS[@]}"; do
                remote_cmd "/bin/rm -rf ${CURRENT_RELEASE}/${dirlink}; /bin/ln -s ${SHARED_DIR}/${dirlink} ${CURRENT_RELEASE}/${dirlink}"
            done
            run_hook "before_link"
            remote_cmd "/bin/rm -f ${CURRENT_RELEASE_LINK}; /bin/ln -s ${CURRENT_RELEASE} ${CURRENT_RELEASE_LINK}"
            run_hook "after_link"
        fi

        if [[ $RUN = "Y" ]]; then
            run_hook "after_deploy"
            clean_old_releases
        fi
    fi
fi

# app related hooks
if [[ $1 = "app" ]]; then
    [[ -f $HOOKS_DIR/app.sh ]] && . $HOOKS_DIR/app.sh
    case $2 in
        start)
            log " -> Starting app ..."
            run_hook 'start'
            ;;
        stop)
            log " -> Stopping app ..."
            run_hook 'stop'
            ;;
        restart)
            log " -> Restarting app ..."
            run_hook 'restart'
            ;;
        status)
            log " -> Checking app status ..."
            run_hook 'status'
            ;;
        *)
            run_hook "${2}"
    esac
fi

END_TIME=$(date +%s)

times=`expr ${END_TIME} - ${START_TIME}`

if [[ $1 == "app" || $1 == "deploy" ]]; then
    log " >> Done."
    log "\nTime: ${times} second(s)."
else
    if [[ $1 = "help" || $1 = "-h" || $1 = "--help" ]]; then
        log "pac is a simple development tool with ssh and rsync, no scm tools required."
        log "\nVersion ${VERSION}\nUsage:"
        log "\t# setup and prepare the deployment on the target servers"
        log "\tPACFILE=/path/to/config.sh ${0} deploy setup\n"
        log "\t# run a deployment"
        log "\tPACFILE=/path/to/config.sh ${0} deploy run\n"
        log "\t# run a fake deployment, check what kind of things will be deployed"
        log "\tPACFILE=/path/to/config.sh ${0} deploy check\n"
        log "\t# roll back the current deployment to a specified one"
        log "\t# e.g. PACFILE=./config.sh pac deploy backto 20121026110008"
        log "\tPACFILE=/path/to/config.sh ${0} deploy backto <release number>\n"
        log "\tPACFILE=/path/to/config.sh ${0} app [start|stop|restart|status]    #  app management with your hooks script"
        exit 0
    else
        if [[ $1 != "" ]]; then
            log "Sorry, pac don't know the command \"$1\"!\n"
        fi
        log "Usage: PACFILE=/path/to/your/project/config.sh ${0} -h"
        log "Initialize: "
        log "\t${0} init # initialize pac in the current directory"
        log "\t${0} init /var/www/app # initialize pac in the \"/var/www/app\" directory"
        exit 0
    fi
fi

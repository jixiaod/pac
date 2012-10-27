#!/bin/bash

# cap.reverse :-) #

# load configurations
if [[ -f $CFILE ]]; then
    . $CFILE
else
    echo ""
    echo "Notice: It seems the CFILE ${CFILE} doesn't exists."
    echo "Run \"CFILE=/path/to/your/project/config.sh ${0} -h\" to see more options."
    echo ""
    exit 1 
fi

RSYNC_OPTS=(-avzP --rsh="ssh -p ${SSH_PORT}")
SSH_OPTS="-p ${SSH_PORT}"
RELEASE_DIR=$REMOTE_DIR/releases
SHARED_DIR=$REMOTE_DIR/shared
CURRENT_RELEASE=$RELEASE_DIR/$(date +%Y%m%d%H%M%S)
CURRENT_RELEASE_LINK=$REMOTE_DIR/current
VERSION="0.0.1"

SSH_CMD="${SSH} ${SSH_OPTS} ${SSH_USER}"

function remote_cmd {
    cmd=$1

    for host in "${SSH_HOSTS[@]}"; do
        log "\n** Remote exec [${host}]: ${cmd}"
        $SSH_CMD@$host $cmd 
    done
}

function run_rsync {
    action=$1

    for host in "${SSH_HOSTS[@]}"; do
        if [[ $action = "setup" ]]; then
            log "** Sync from \"${LOCAL_DIR}/public/\" to \"${SSH_USER}@${host}:${SHARED_DIR}/public/\""
            $RSYNC "${RSYNC_OPTS[@]}" $LOCAL_DIR/public/ $SSH_USER@$host:$SHARED_DIR/public/
        else
            echo "** Sync from \"${LOCAL_DIR}/\" to \"${SSH_USER}@${host}:${SHARED_DIR}/cached-copy/\""
            $RSYNC "${RSYNC_OPTS[@]}" --delete --exclude-from=$LOCAL_DIR/script/.rsync_exclude $LOCAL_DIR/ $SSH_USER@$host:$SHARED_DIR/cached-copy/
        fi
    done
}

function log {
    echo -e $1
}

function run_hook {
    func=$1
    type $func | grep 'function' > /dev/null && $func
}

function clean_old_releases {
    log "! Clean old releases ..."
    for host in "${SSH_HOSTS[@]}"; do
        files=`${SSH_CMD}@${host} "cd ${RELEASE_DIR} && ls | sort"`
        read -a array <<< $files 
        length=`expr "${#array[@]}" - ${LIMIT_RELEASES}`

        for (( i = 0; i < ${length}; i++ ))
        do
            cmd="rm -rf ${RELEASE_DIR}/${array[$i]}"
            echo "** Remote exec [${host}]: ${cmd}"
            $SSH_CMD@$host $cmd 
        done
    done
}

START_TIME=$(date +%s)

# deploy it
if [[ $1 = "deploy" ]]; then
    [[ -f $HOOKS_DIR/deploy.sh ]] && . $HOOKS_DIR/deploy.sh
    if [[ $2 = "setup" ]]; then
        log "!! Deployment setup ..."

        # join the array with ","

        ORIGIN_IFS=$IFS
        IFS=","
        MY_SHARED_DIRS="${SHARED_DIRS[*]},cached-copy"
        IFS=$ORIGIN_IFS

        remote_cmd "/bin/mkdir -p ${SHARED_DIR}/{${MY_SHARED_DIRS}} ${RELEASE_DIR}"
        run_rsync "setup"
    else
        if [[ $2 != "run" ]]; then
            RSYNC_OPTS+=(--dry-run)
            RUN="N"
            log "!! Prepare for deploying ..."
        else
            RUN="Y"
            log "!! Deploying ..."
        fi
        # deploying ...
        if [[ $RUN = "Y" ]]; then
            run_hook "before_deploy"
        fi

        if [[ $2 = "backto" ]]; then
            CURRENT_RELEASE=$RELEASE_DIR/$3
        else
            run_rsync "deploy"
            remote_cmd "/bin/cp -r -p ${SHARED_DIR}/cached-copy ${CURRENT_RELEASE}"
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
        fi

        clean_old_releases
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
        log "pac is a simple deployment tool with rsync and ssh, no scm required."
        log "\nVersion ${VERSION}\nUsage:"
        log "\t# setup and prepare the deployment on the target servers"
        log "\tCFILE=/path/to/config.sh ${0} deploy setup\n"
        log "\t# run a deployment"
        log "\tCFILE=/path/to/config.sh ${0} deploy run\n"
        log "\t# run a fake deployment, check what kind of things will be deployed"
        log "\tCFILE=/path/to/config.sh ${0} deploy check\n"
        log "\t# roll back the current deployment to a specified one"
        log "\t# e.g. CFILE=./config.sh cap deploy backto 20121026110008"
        log "\tCFILE=/path/to/config.sh ${0} deploy backto <release number>\n"
        log "\tCFILE=/path/to/config.sh ${0} app [start|stop|restart|status]    #  app management with your hooks script"
        exit 0
    else
        if [[ $1 != "" ]]; then
            log "Invalid parameter $1 given"
        fi
        log "Usage: CFILE=/path/to/your/project/config.sh ${0} -h"
        exit 1
    fi
fi

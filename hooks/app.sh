#!/bin/bash
function start {
    # run remote command in the current release link

    # start app
    remote_cmd "cd ${CURRENT_RELEASE_LINK} && ls"
}

function stop {
    # stop app 
}

function restart {
    # restart app
}

function status {
    # check the status of your app
    remote_cmd "ps aux | grep nginx"
}

function releases {
    # show the releases
    remote_cmd "ls -al ${RELEASE_DIR}"
}

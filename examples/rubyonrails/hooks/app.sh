#!/bin/bash
function start {
    remote_cmd "/usr/local/bin/thin start -C ${CURRENT_RELEASE_LINK}/config/thin.yml"
}

function stop {
    remote_cmd "/usr/local/bin/thin stop -C ${CURRENT_RELEASE_LINK}/config/thin.yml"
}

function restart {
    remote_cmd "/usr/local/bin/thin restart -C ${CURRENT_RELEASE_LINK}/config/thin1.yml"
}

function status {
    remote_cmd "ps aux | grep thin"
}

function releases {
    remote_cmd "ls -al ${RELEASE_DIR}"
}

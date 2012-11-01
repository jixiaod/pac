#!/bin/bash

# step 1
function before_deploy {
    echo "before deploy ..."
}

# step 2
function before_link {
    # run remote command
    echo "before link"
    remote_cmd "cd ${CURRENT_RELEASE} && php clean_apc_cache.php"
}

# step 3
function after_link {
    echo "after link ..."
}

# step 4
function after_deploy {
    echo "after deploy ..."
}

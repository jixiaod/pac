#!/bin/bash

function before_deploy {
    echo "before deploy ..."
}

function after_deploy {
    echo "after deploy ..."
}

function before_link {
    remote_cmd "RAILS_ENV=production; cd ${CURRENT_RELEASE} && /usr/local/bin/bundle install && /usr/local/bin/rake assets:precompile"
}

function after_link {
    echo "after link ..."
}

# pac

pac is a simple deployment tool with ssh and rsync, no scm tools required.
It can work with any kind of projects which need to deploy to 1 or more \*nix servers.

## Before start

You may need to create a ssh account (e.g. "www") on a local server (aka "deployment server"), then on the remote server(s), allow the ssh account to login via public ssh key instead of password, see [Setting up SSH public/private keys](http://www.ece.uci.edu/~chou/ssh-key.html) for more.

## Quick start

### Installation / Update

    # wget https://raw.github.com/xianhuazhou/pac/master/pac.sh -O /usr/bin/pac
    # chmod +x /usr/bin/pac

### Initialization

    $ cd /path/to/your/project
    $ pac init

### Change your pac settings in the directory ".pac/" 

There is a main configuration file called "config.sh", you can open and change the basic settings. Also, there is a "hooks" directory, you can put some hook functions there.
To exclude some files to deploy, you can update the file "hooks/rsync\_exclude".
You can check the [examples](https://github.com/xianhuazhou/pac/tree/master/examples) direcotry for more.

### Prepare for the first deploymet 

In your project directory, run:

    $ pac deploy setup 

### Do a fake deployment to see what kind of files will be deployed to your servers

    $ pac deploy

### If everything looks fine, you can do a real deployment by the following command:

    $ pac deploy run

### Run a remote command
    $ pac run "ls" # run the command in all servers
    $ pac run "ps aux" your-remote-server.name # run only in the specified server

### help 

    $ pac help

### environment variable: PACFILE

The environment variable is using by pac to determine how to do the deployment, by default it will set it to the file ".pac/config.sh" based your current working directory, however, you can change this, e.g.:

    $ PACFILE=/path/to/somewhere/pac/config.sh pac deploy

### Other deployment tools

[Capistrano](https://github.com/capistrano/capistrano)
[Capifony](http://capifony.org/)

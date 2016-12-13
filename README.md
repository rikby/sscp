# `sscp` Shell Tool
Download/upload whole directories to/from remote environments.

In common sense it's something similar to SFTP aliases.

## How it works?
It uses SSH for running commands (for pack/unpack files, etc.) and SCP for deploy/download target file/archive of files.

## Why?
The script archive whole directory and it much faster than deployment with IDE like IDEA because it performs one-by-one.

# Installation
At first, we need to download binary file
## Download bin file
```shell
$ curl -Ls https://raw.github.com/rikby/sscp/master/download | bash
```
[Download extra options](doc/download.md)

Now it should be ready to use.
```shell
$ sscp --help
```

## Global environment variables
```
$ sscp vars
# default name of config file
SSCP_RC=.sscprc
# directory where base .sscprc file (your home directory)
SSCP_BASE_DIR=/root
# SSH binary file
SSCP_SSH_BIN=ssh
# SCP binary file
SSCP_SCP_BIN=scp
# Default exclude list
SSCP_EXCLUDE=.idea
# Default connection
SSCP_CONNECT=vagrant@127.0.0.1
# Default temp directory. It uses in a remote server as well
SSCP_TEMP=~
# disable using colors
SSCP_NO_COLOR=0
# default verbose level (0- silent, 1- normal, 2- "very" mode, 3- debug)
SSCP_VERBOSE=1
```

You may print allowed environment variables:
```
$ sscp vars
```

## Set connection parameters in file `.sscprc`
(Example with vagrant connection.)

Initial `~/.sscprc` file with example of the connection to Vagrant VM.
```shell
connect='your-host'
```

### Example of set up SSH config by using Vagrant
But it will be more useful to add a SSH configuration:
```
$ cat ~/.ssh/config
Host your-host yh
  HostName your-host
  User vagrant
  Port 2200
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile D:/vms/my-vm/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  ForwardAgent yes
```
And define your connection only:
```shell
connect='your-host'
```

```
$ sscp test
OK
```

See `vagrant ssh-config` for vagrant.

### Base paths
Also you may add base paths:
```shell
remote_base_dir='/var/www'
local_base_dir='/d/home'
```
### Default values of `.sscprc`
By default it has values:
```shell
connect='vagrant@127.0.0.1'
port=''
# Base directory for remote VM/server
remote_base_dir=''
# Base directory for for the current workstation
local_base_dir=''
# It will use port if exists
ssh_connect="ssh ${connect} -p ${port}"
scp_connect="scp -P ${port}"
```

## Using format
To **upload** folder it has format
```shell
$ sscp upload LOCAL_PATH REMOTE_PATH [-p PORT]
```
To **download** folder it has format
```shell
$ sscp download REMOTE_PATH [LOCAL_PATH] [-p PORT]
```
To get expanded help please use command:
```shell
$ sscp --help
```

# Run tests
[Tests document](doc/run-tests.md).

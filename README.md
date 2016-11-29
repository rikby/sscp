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
Global vars:
- `SSCP_RC=.sscprc`     - Global resource file
- `SSCP_SSH_BIN=ssh`    - SSH bin file
- `SSCP_SCP_BIN=scp`    - SCP bin file
- `SSCP_EXCLUDE=.idea`  - Custom exclude list.
- `SSCP_TEMP=~`         - Temp directory for archive. It uses for remote servers.
- `SSCP_CONNECT=.vagrant@127.0.0.1`
                    - Connection host and user.

## Set connection parameters
(Example with vagrant connection.)

Initial `~/.sscprc` file with example of the connection to Vagrant VM.
```shell
connect='your-host'
```

### With SSH config
But it seems more useful will be add a SSH configuration:
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
connect='vagrant@your-host'
```

See `vagrant ssh-config` for vagrant.

### Base paths
Also you may add base paths:
```shell
remote_base_dir='/var/www'
local_base_dir='/d/home'
```
### Default values
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

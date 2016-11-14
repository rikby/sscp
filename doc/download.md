# Download options
- Simple Download
```shell
$ curl -Ls https://raw.github.com/rikby/sscp/master/download | bash
```
- Download a particular version
```shell
$ curl -Ls https://raw.github.com/rikby/sscp/master/download | bash -s -- --version 0.1.0
```
- Download and set custom path to binary file
```shell
$ curl -Ls https://raw.github.com/rikby/sscp/master/download | bash -s -- --file /usr/bin/sscp
```
- Show available versions
```shell
$ curl -Ls https://raw.github.com/rikby/sscp/master/download | bash -s -- --versions
```

#!/usr/bin/env bats
# Run tests by using bats
# https://github.com/sstephenson/bats

ERR_FATAL=1
ERR_LOGIC=2
ERR_PARAMS=3
ERR_FILE_SYSTEM=4
ERR_CONNECTION=6 # failed test for connection

status=0
output=''
@test "Single run." {
  run sscp 2>&1
  [ "${status}" -eq 3 ]
  [[ "$(echo ${output} | sed -re 's/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g')" =~ 'error: Empty action type.' ]]
}

@test "Single run without colors." {
  export SSCP_NO_COLOR=1
  run sscp 2>&1
  [ "${status}" -eq 3 ]
  [[ "${output}" =~ 'error: Empty action type.' ]]
}

@test "Test --help." {
  sscp --help | grep 'SSCP Shell Tool '$(cat ./version)
}

@test "Test -h." {
  sscp -h | grep 'SSCP Shell Tool '$(cat ./version)
}

@test "Test config-file" {
  mkdir -p '/tmp/sscp-bats-tests'
  cd /tmp/sscp-bats-tests
  touch /tmp/sscp-bats-tests/.sscprc
  [ '/tmp/sscp-bats-tests/.sscprc' == "$(sscp config-file)" ]
}

@test "Test status of show-vars." {
  run sscp show-vars
  [ "${status}" -eq 0 ]
}

@test "Test show-ssh-connection from .sscprc." {
  rm -rf /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser
  cat <<- EOF > /tmp/sscp-bats-tests/tuser/.sscprc
connect='invalid.localhost'
port=19999
EOF
  cd /tmp/sscp-bats-tests/tuser

  run sscp show-ssh-connection

  [ "${status}" -eq 0 ]
  [ "${output}" == 'ssh invalid.localhost -p 19999' ]
}

@test "Test showing vars." {
  run sscp vars

  [ "${status}" -eq 0 ]
  echo "${output}" | grep 'SSCP_RC=.sscprc'
}

@test "Test --host" {
  run sscp test --host localhost
  [ "${output}" == 'OK' ]
}

@test "Test --host with silent mode" {
  run sscp test --host localhost --silent
  [ "${output}" == '' ]
  [ ${status} == 0 ]
}

@test "Test --host with using SSCP_VERBOSE" {
  export SSCP_VERBOSE=0
  run sscp test --host localhost
  [ "${output}" == '' ]
  [ ${status} == 0 ]
}

@test "Test --host with using --silent" {
  run sscp test --host localhost --silent
  [ "${output}" == '' ]
  [ ${status} == 0 ]
}

@test "Test (negative) --host" {
  export SSCP_NO_COLOR=1
  run sscp test --host wrong-host
  [[ "${output}" =~ 'error: Cannot connect to the server (wrong-host ).' ]]
}

@test "Test variable 'connect' in .sscprc" {
  cd /tmp/sscp-bats-tests
  cat <<- EOF > /tmp/sscp-bats-tests/.sscprc
connect='localhost'
EOF

  run sscp test
  rm -f /tmp/sscp-bats-tests/.sscprc

  [ 0 == ${status} ]
  [ 'OK' == "${output}" ]
}

@test "Test overriding host and port from .sscprc with params (show-ssh-connection)." {
  rm -rf /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser
  cat <<- EOF > /tmp/sscp-bats-tests/tuser/.sscprc
connect='invalid.localhost'
port=19999
EOF
  cd /tmp/sscp-bats-tests/tuser

  run sscp show-ssh-connection --host localhost --port 22

  [ "${status}" -eq 0 ]
  [ "${output}" == 'ssh localhost -p 22' ]
}

@test "Test variable SSCP_CONNECT." {
  export SSCP_CONNECT=localhost
  if [ -f ~/.ssh/known_hosts ]; then
    ssh-keygen -R 127.0.0.1 || true
  fi

  run sscp test

  [ 0 == ${status} ]
  [ 'OK' == "${output}" ]
}

@test "Test (negative) port." {
  export SSCP_NO_COLOR=1
  run sscp test --host localhost --port 1234

  [ "${status}" -eq ${ERR_CONNECTION} ]
  [[ 'error: Cannot connect to the server (localhost 1234).' =~ "${output}" ]]
}

@test "Test (negative) variable 'port' in .sscprc" {
  cd /tmp/sscp-bats-tests
  cat <<- EOF > /tmp/sscp-bats-tests/.sscprc
connect='localhost'
port=9999
EOF

  export SSCP_NO_COLOR=1
  run sscp test

  [ "${status}" -eq ${ERR_CONNECTION} ]
  [[ 'error: Cannot connect to the server (localhost 9999).' =~ "${output}" ]]
}

@test "Test download." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser/test1
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/.gitignore
  touch /tmp/sscp-bats-tests/tuser/.hidden
  touch /tmp/sscp-bats-tests/tuser/test1/some-file

  run sscp D /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target --host localhost

  [ "${status}" -eq 0 ]

  expected=$(printf \
"./test1/some-file
./.hidden")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test download with VCS files." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser/test1
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/.gitignore
  touch /tmp/sscp-bats-tests/tuser/.hidden
  touch /tmp/sscp-bats-tests/tuser/test1/some-file
  touch /tmp/sscp-bats-tests/tuser/test1/.gitignore

  run sscp D /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target --host localhost --use-vcs

  [ "${status}" -eq 0 ]

  expected=$(printf \
"./test1/some-file
./test1/.gitignore
./.gitignore
./.hidden")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser/test1
  mkdir -p /tmp/sscp-bats-tests/tuser-target
  chown tuser -R /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/.gitignore
  touch /tmp/sscp-bats-tests/tuser/.hidden
  touch /tmp/sscp-bats-tests/tuser/test1/some-file
  touch /tmp/sscp-bats-tests/tuser/test1/.gitignore

  run sscp U /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target --host localhost

  [ "${status}" -eq 0 ]

  expected=$(printf \
"./test1/some-file
./.hidden")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload with VCS files." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser/test1
  mkdir -p /tmp/sscp-bats-tests/tuser-target
  chown tuser -R /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/.gitignore
  touch /tmp/sscp-bats-tests/tuser/.hidden
  touch /tmp/sscp-bats-tests/tuser/test1/some-file
  touch /tmp/sscp-bats-tests/tuser/test1/.gitignore

  run sscp U /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target --host localhost --use-vcs

  [ "${status}" -eq 0 ]

  expected=$(printf \
"./test1/some-file
./test1/.gitignore
./.gitignore
./.hidden")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test creating destination path during upload." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser/test1
  mkdir -p /tmp/sscp-bats-tests/tuser-target
  chown tuser -R /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/.gitignore
  touch /tmp/sscp-bats-tests/tuser/.hidden
  touch /tmp/sscp-bats-tests/tuser/test1/some-file
  touch /tmp/sscp-bats-tests/tuser/test1/.gitignore

  run sscp U /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target/new-dir --host localhost --create-destination

  [ "${status}" -eq 0 ]

  expected=$(printf \
"./test1/some-file
./.hidden")
  result=$(cd /tmp/sscp-bats-tests/tuser-target/new-dir; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test download with predefined paths." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser \
    /tmp/sscp-bats-tests/some
  mkdir -p /tmp/sscp-bats-tests/some
  cd /tmp/sscp-bats-tests/some
  cat <<- EOF > .sscprc
connect='localhost'
port=22
remote_base_dir='/tmp/sscp-bats-tests/tuser'
local_base_dir='/tmp/sscp-bats-tests/tuser-target'
EOF

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  run sscp D file1 .

  [ "${status}" -eq 0 ]

  expected='./file1'
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload with predefined paths." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser \
    /tmp/sscp-bats-tests/some

  # create not related directory and put .sscprc file in there
  mkdir -p /tmp/sscp-bats-tests/some
  cd /tmp/sscp-bats-tests/some
  cat <<- EOF > .sscprc
connect='root@localhost'
port=22
remote_base_dir='/tmp/sscp-bats-tests/tuser-target'
local_base_dir='/tmp/sscp-bats-tests/tuser'
EOF

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  run /code/sscp upload file1 .

  [ "${status}" -eq 0 ]

  expected='./file1'
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload with predefined remote path and relative local path in the command." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser \
    /tmp/sscp-bats-tests/some

  mkdir -p /tmp/sscp-bats-tests/tuser
  cd /tmp/sscp-bats-tests/tuser

  cat <<- EOF > .sscprc
connect='root@localhost'
remote_base_dir='/tmp/sscp-bats-tests/tuser-target'
EOF

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  run /code/sscp upload file1

  [ "${status}" -eq 0 ]

  expected='./file1'
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test download root predefined path without 'path' params." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser \
    /tmp/sscp-bats-tests/some
  mkdir -p /tmp/sscp-bats-tests/some
  cd /tmp/sscp-bats-tests/some
  cat <<- EOF > .sscprc
connect='localhost'
port=22
remote_base_dir='/tmp/sscp-bats-tests/tuser'
local_base_dir='/tmp/sscp-bats-tests/tuser-target'
EOF

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  run sscp D

  [ "${status}" -eq 0 ]

  expected='./file1'
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload root predefined path without 'path' params." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser \
    /tmp/sscp-bats-tests/some
  mkdir -p /tmp/sscp-bats-tests/some
  cd /tmp/sscp-bats-tests/some
  cat <<- EOF > .sscprc
connect='root@localhost'
port=22
local_base_dir='/tmp/sscp-bats-tests/tuser'
remote_base_dir='/tmp/sscp-bats-tests/tuser-target'
EOF

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  run sscp U

  [ "${status}" -eq 0 ]

  expected='./file1'
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test downloading archive into current directory without unpacking." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1

  cd /tmp/sscp-bats-tests/tuser-target
  run sscp D /tmp/sscp-bats-tests/tuser --host localhost

  [ "${status}" -eq 0 ]

  expected=$(printf "./tuser.tar.gz")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload manually created archive." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1
  tar czf /tmp/sscp-bats-tests/ar.tar.gz -C /tmp/sscp-bats-tests/tuser .

  run sscp U /tmp/sscp-bats-tests/ar.tar.gz /tmp/sscp-bats-tests/tuser-target --host root@localhost

  [ "${status}" -eq 0 ]

  expected=$(printf "./ar.tar.gz")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test upload and unpack manually created archive." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1
  tar czf /tmp/sscp-bats-tests/ar.tar.gz -C /tmp/sscp-bats-tests/tuser .

  run sscp U /tmp/sscp-bats-tests/ar.tar.gz /tmp/sscp-bats-tests/tuser-target --host root@localhost --unpack

  [ "${status}" -eq 0 ]

  expected=$(printf "./file1")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test download manually created archive." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1
  tar czf /tmp/sscp-bats-tests/ar.tar.gz -C /tmp/sscp-bats-tests/tuser .

  run sscp D /tmp/sscp-bats-tests/ar.tar.gz /tmp/sscp-bats-tests/tuser-target --host root@localhost

  [ "${status}" -eq 0 ]

  expected=$(printf "./ar.tar.gz")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

@test "Test download and unpack manually created archive." {
  rm -rf /tmp/sscp-bats-tests/tuser-target \
    /tmp/sscp-bats-tests/tuser

  mkdir -p /tmp/sscp-bats-tests/tuser
  mkdir -p /tmp/sscp-bats-tests/tuser-target

  touch /tmp/sscp-bats-tests/tuser/file1
  tar czf /tmp/sscp-bats-tests/ar.tar.gz -C /tmp/sscp-bats-tests/tuser .

  run sscp D /tmp/sscp-bats-tests/ar.tar.gz /tmp/sscp-bats-tests/tuser-target --host root@localhost --unpack

  [ "${status}" -eq 0 ]

  expected=$(printf "./file1")
  result=$(cd /tmp/sscp-bats-tests/tuser-target; find . -type f)

  [[ "${expected}" == "${result}" ]]
}

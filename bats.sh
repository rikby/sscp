#!/usr/bin/env bats

@test "Single run" {
  sscp | sed -re 's/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g' | grep 'error: Empty action type.'
}

@test "Single run without colors" {
  export SSCP_NO_COLOR=1
  sscp | grep 'error: Empty action type.'
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

@test "Test --host" {
  cd /
  [ "$(sscp test --host localhost)" == 'OK' ]
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

  [ "${status}" -eq 2 ]
  [ 'error: Cannot connect to the server (localhost 1234).' == "${output}" ]
}

@test "Test (negative) variable 'port' in .sscprc" {
  cd /tmp/sscp-bats-tests
  cat <<- EOF > /tmp/sscp-bats-tests/.sscprc
connect='localhost'
port=9999
EOF

  export SSCP_NO_COLOR=1
  run sscp test
  [ "${status}" -eq 2 ]
  rm -f /tmp/sscp-bats-tests/.sscprc

  [ 'error: Cannot connect to the server (localhost 9999).' == "${output}" ]
}

#@test "Test failed deploy." {
#  rm -rf /tmp/sscp-bats-tests/tuser-target \
#    /tmp/sscp-bats-tests/tuser
#
#  mkdir -p /tmp/sscp-bats-tests/tuser/test1
#  mkdir -p /tmp/sscp-bats-tests/tuser-target
#
#  touch /tmp/sscp-bats-tests/tuser/.gitignore
#  touch /tmp/sscp-bats-tests/tuser/.hidden
#  touch /tmp/sscp-bats-tests/tuser/test1/some-file
#
#  sscp D /tmp/sscp-bats-tests/tuser /tmp/sscp-bats-tests/tuser-target --host localhost
#
#  read -r -d '' expected <<'EOF'
#./test1/some-file
#./.hidden
#EOF
#  [ ${expected} == $(cd /tmp/sscp-bats-tests/tuser-target; find . -type f) ]
#}

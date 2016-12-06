#!/usr/bin/env bats

@test "Single run" {
  result="$(sscp)"
  [ "$result" -eq 4 ]
}

@test "Test help 1." {
  result="$(sscp --help)"
  [ "$result" -eq 4 ]
}

@test "Test help 2." {
  result="$(sscp -h)"
  [ "$result" -eq 4 ]
}

#!/usr/bin/env bats

kenvx() {
  bash "$PROJECT_ROOT_DIR"/kenvx "$@"
}

@test "fails on missing arguments" {
  run kenvx
  # echo "${output}" >&3
  [ "$status" -eq 1 ]
}

@test "fails on invalid resource kind" {
  run kenvx invalid/app
  # echo "${output}" >&3
  [ "$status" -eq 1 ]
  [ "$output" = "error: the server doesn't have a resource type \"invalid\"" ]
}

@test "fails on invalid resource name" {
  run kenvx deployment/notfound
  # echo "${output}" >&3
  [ "$status" -eq 1 ]
  [ "$output" = "Error from server (NotFound): deployments.apps \"notfound\" not found" ]
}

@test "deployment/noenv: prints ENV (nothing)" {
  run kenvx deployment/noenv
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "" ]
}

@test "deployment/noenv: exec with ENV" {
  run kenvx deployment/noenv -- sh -c 'echo exec'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "exec" ]
}

@test "deployment/emptyenv: prints ENV (nothing)" {
  run kenvx deployment/emptyenv
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "" ]
}

@test "deployment/emptyenv: exec with ENV" {
  run kenvx deployment/emptyenv -- sh -c 'echo exec'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "exec" ]
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var single)" {
  run kenvx deployment/emptyenv MYVAR=added -- sh -c 'echo "$MYVAR"'
  [ "$status" -eq 0 ]
  # echo "$output" >&3
  [ "$output" = "added" ]
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var multi)" {
  run kenvx deployment/emptyenv MYVAR="added\nmulti" -- sh -c 'echo "$MYVAR"'
  [ "$status" -eq 0 ]
  # echo "$output" >&3
  [ "$output" = "added
multi" ]
}

# shellcheck disable=SC2016
@test "deployment/sample: exec with ENV multiline override" {
  run kenvx deployment/sample SAMPLE_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "$status" -eq 0 ]
  # echo "$output" >&3
  [ "$output" = "override
multi" ]
}

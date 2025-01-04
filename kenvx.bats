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

EXPECTED_PRINT_OUTPUT=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
SAMPLE_SECRET=via secret
SAMPLE_SECRET_64=via secret
EOF
)

EXPECTED_EXEC_OUTPUT=$(cat <<EOF
SAMPLE_SINGLE
Simple string
SAMPLE_MULTI
Multi line
value
SAMPLE_CONFIGMAP
via config map
SAMPLE_SECRET
via secret
SAMPLE_SECRET_64
via secret
EOF
)

# Using single quotes to prevent premature expansion of variables
# shellcheck disable=SC2016
EXEC_PRINTF='printf "%s\n" \
  "SAMPLE_SINGLE" "$SAMPLE_SINGLE" \
  "SAMPLE_MULTI" "$SAMPLE_MULTI" \
  "SAMPLE_CONFIGMAP" "$SAMPLE_CONFIGMAP" \
  "SAMPLE_SECRET" "$SAMPLE_SECRET" \
  "SAMPLE_SECRET_64" "$SAMPLE_SECRET_64"'

@test "deployment/sample: prints ENV" {
  run kenvx deployment/sample
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_PRINT_OUTPUT" ]
}

@test "deployment/sample: exec with ENV" {
  run kenvx deployment/sample -- sh -c "$EXEC_PRINTF"
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_EXEC_OUTPUT" ]
}

@test "cronjob/sample: prints ENV" {
  run kenvx cronjob/sample
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_PRINT_OUTPUT" ]
}

@test "cronjob/sample: exec with ENV" {
  run kenvx cronjob/sample -- sh -c "$EXEC_PRINTF"
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_EXEC_OUTPUT" ]
}

@test "job/sample: prints ENV" {
  run kenvx job/sample
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_PRINT_OUTPUT" ]
}

@test "job/sample: exec with ENV" {
  run kenvx job/sample -- sh -c "$EXEC_PRINTF"
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_EXEC_OUTPUT" ]
}

@test "daemonset/sample: prints ENV" {
  run kenvx daemonset/sample
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_PRINT_OUTPUT" ]
}

@test "daemonset/sample: exec with ENV" {
  run kenvx daemonset/sample -- sh -c "$EXEC_PRINTF"
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_EXEC_OUTPUT" ]
}

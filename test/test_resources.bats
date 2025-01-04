#!/usr/bin/env bats

kenvx() {
  bash "$PROJECT_ROOT_DIR"/kenvx "$@"
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

@test "pod/sample: prints ENV" {
  run kenvx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)"
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "$EXPECTED_PRINT_OUTPUT" ]
}

@test "pod/sample: exec with ENV" {
  run kenvx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)" -- sh -c "$EXEC_PRINTF"
  [ "$status" -eq 0 ]
  # echo "$output" >&3
  [ "$output" = "$EXPECTED_EXEC_OUTPUT" ]
}

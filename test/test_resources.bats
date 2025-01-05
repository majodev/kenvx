#!/usr/bin/env bats

setup_file() {
  kubectl config use-context kind-kenvx
  kubectl config set-context --current --namespace default
}

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert # https://github.com/bats-core/bats-assert
}

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
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "deployment/sample: exec with ENV" {
  run kenvx deployment/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "cronjob/sample: prints ENV" {
  run kenvx cronjob/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "cronjob/sample: exec with ENV" {
  run kenvx cronjob/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "job/sample: prints ENV" {
  run kenvx job/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "job/sample: exec with ENV" {
  run kenvx job/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "daemonset/sample: prints ENV" {
  run kenvx daemonset/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "daemonset/sample: exec with ENV" {
  run kenvx daemonset/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "pod/sample: prints ENV" {
  run kenvx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)"
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "pod/sample: exec with ENV" {
  run kenvx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)" -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

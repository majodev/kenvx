#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert # https://github.com/bats-core/bats-assert
}

kubectl-envx() {
  "$PROJECT_ROOT_DIR"/kubectl-envx "$@"
}

EXPECTED_PRINT_OUTPUT=$(cat <<EOF
SAMPLE_FROM_MULTI=Multi line
value
SAMPLE_FROM_SINGLE=single
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
SAMPLE_FROM_SINGLE
single
SAMPLE_FROM_MULTI
Multi line
value
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
  "SAMPLE_FROM_SINGLE" "$SAMPLE_FROM_SINGLE" \
  "SAMPLE_FROM_MULTI" "$SAMPLE_FROM_MULTI" \
  "SAMPLE_SECRET" "$SAMPLE_SECRET" \
  "SAMPLE_SECRET_64" "$SAMPLE_SECRET_64"'

@test "deployment/sample: prints ENV" {
  run kubectl-envx deployment/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "deployment/sample: exec with ENV" {
  run kubectl-envx deployment/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "cronjob/sample: prints ENV" {
  run kubectl-envx cronjob/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "cronjob/sample: exec with ENV" {
  run kubectl-envx cronjob/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "job/sample: prints ENV" {
  run kubectl-envx job/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "job/sample: exec with ENV" {
  run kubectl-envx job/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "daemonset/sample: prints ENV" {
  run kubectl-envx daemonset/sample
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "daemonset/sample: exec with ENV" {
  run kubectl-envx daemonset/sample -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

@test "pod/sample: prints ENV" {
  run kubectl-envx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)"
  assert_success
  assert_output "$EXPECTED_PRINT_OUTPUT"
}

@test "pod/sample: exec with ENV" {
  run kubectl-envx "$(kubectl get pods -n default -lapp=sample -o name | head -n 1)" -- sh -c "$EXEC_PRINTF"
  assert_success
  assert_output "$EXPECTED_EXEC_OUTPUT"
}

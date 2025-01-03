#!/usr/bin/env bats

kenvx() {
  bash "${PROJECT_ROOT_DIR}"/kenvx.sh "$@"
}

@test "deployment/sample: prints ENV" {
  run kenvx deployment/sample
  [ "${status}" -eq 0 ]

  expected_output=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
EOF
)
  # echo "${output}" >&3
  [ "$output" = "$expected_output" ]
}

@test "deployment/sample: exec with ENV" {

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_SINGLE"'
  [ "${status}" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Simple string" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "${status}" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Multi line
value" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_CONFIGMAP"'
  [ "${status}" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via config map" ]
}
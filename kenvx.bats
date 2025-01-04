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

@test "deployment/sample: prints ENV" {
  run kenvx deployment/sample
  [ "$status" -eq 0 ]

  expected_output=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
SAMPLE_SECRET=via secret
SAMPLE_SECRET_64=via secret
EOF
)
  # echo "${output}" >&3
  [ "$output" = "$expected_output" ]
}

# shellcheck disable=SC2016
# Using single quotes to prevent premature expansion of variables
@test "deployment/sample: exec with ENV" {

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_SINGLE"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Simple string" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Multi line
value" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_CONFIGMAP"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via config map" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_SECRET"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]

  run kenvx deployment/sample -- sh -c 'echo "$SAMPLE_SECRET_64"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]
}

@test "cronjob/sample: prints ENV" {
  run kenvx cronjob/sample
  [ "$status" -eq 0 ]

  expected_output=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
SAMPLE_SECRET=via secret
SAMPLE_SECRET_64=via secret
EOF
)
  # echo "${output}" >&3
  [ "$output" = "$expected_output" ]
}

# shellcheck disable=SC2016
# Using single quotes to prevent premature expansion of variables
@test "cronjob/sample: exec with ENV" {

  run kenvx cronjob/sample -- sh -c 'echo "$SAMPLE_SINGLE"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Simple string" ]

  run kenvx cronjob/sample -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Multi line
value" ]

  run kenvx cronjob/sample -- sh -c 'echo "$SAMPLE_CONFIGMAP"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via config map" ]

  run kenvx cronjob/sample -- sh -c 'echo "$SAMPLE_SECRET"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]

  run kenvx cronjob/sample -- sh -c 'echo "$SAMPLE_SECRET_64"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]
}

@test "job/sample: prints ENV" {
  run kenvx job/sample
  [ "$status" -eq 0 ]

  expected_output=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
SAMPLE_SECRET=via secret
SAMPLE_SECRET_64=via secret
EOF
)
  # echo "${output}" >&3
  [ "$output" = "$expected_output" ]
}

# shellcheck disable=SC2016
# Using single quotes to prevent premature expansion of variables
@test "job/sample: exec with ENV" {

  run kenvx job/sample -- sh -c 'echo "$SAMPLE_SINGLE"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Simple string" ]

  run kenvx job/sample -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Multi line
value" ]

  run kenvx job/sample -- sh -c 'echo "$SAMPLE_CONFIGMAP"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via config map" ]

  run kenvx job/sample -- sh -c 'echo "$SAMPLE_SECRET"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]

  run kenvx job/sample -- sh -c 'echo "$SAMPLE_SECRET_64"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]
}


@test "daemonset/sample: prints ENV" {
  run kenvx daemonset/sample
  [ "$status" -eq 0 ]

  expected_output=$(cat <<EOF
SAMPLE_SINGLE=Simple string
SAMPLE_MULTI=Multi line
value
SAMPLE_CONFIGMAP=via config map
SAMPLE_SECRET=via secret
SAMPLE_SECRET_64=via secret
EOF
)
  # echo "${output}" >&3
  [ "$output" = "$expected_output" ]
}

# shellcheck disable=SC2016
# Using single quotes to prevent premature expansion of variables
@test "daemonset/sample: exec with ENV" {

  run kenvx daemonset/sample -- sh -c 'echo "$SAMPLE_SINGLE"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Simple string" ]

  run kenvx daemonset/sample -- sh -c 'echo "$SAMPLE_MULTI"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "Multi line
value" ]

  run kenvx daemonset/sample -- sh -c 'echo "$SAMPLE_CONFIGMAP"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via config map" ]

  run kenvx daemonset/sample -- sh -c 'echo "$SAMPLE_SECRET"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]

  run kenvx daemonset/sample -- sh -c 'echo "$SAMPLE_SECRET_64"'
  [ "$status" -eq 0 ]
  # echo "${output}" >&3
  [ "$output" = "via secret" ]
}
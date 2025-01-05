#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert # https://github.com/bats-core/bats-assert
}

kenvx() {
  bash "$PROJECT_ROOT_DIR"/kenvx "$@"
}

@test "fails on missing arguments" {
  run kenvx
  assert_failure
  assert_output --partial "Error: Resource (kind/name) is required"
  assert_output --partial "Usage:"
}

@test "fails on invalid resource kind" {
  run kenvx invalid/app
  assert_failure
  assert_output "error: the server doesn't have a resource type \"invalid\""
}

@test "fails on invalid resource name" {
  run kenvx deployment/notfound
  assert_failure
  assert_output "Error from server (NotFound): deployments.apps \"notfound\" not found"
}

@test "fails on invalid namespace" {
  run kenvx deploy/sample -n thisnamespaceisnotfound
  assert_failure
  assert_output "Error from server (NotFound): namespaces \"thisnamespaceisnotfound\" not found"
}

@test "fails on malformed env var" {
  run kenvx deployment/sample "INVALID" -- env
  assert_failure
  assert_output --partial "Error: Invalid argument 'INVALID'"
}

@test "deployment/noenv: prints ENV (nothing)" {
  run kenvx deployment/noenv
  assert_success
  assert_output ""
}

@test "deployment/noenv: exec with ENV" {
  run kenvx deployment/noenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

@test "deployment/emptyenv: prints ENV (nothing)" {
  run kenvx deployment/emptyenv
  assert_success
  assert_output ""
}

@test "deployment/emptyenv: exec with ENV" {
  run kenvx deployment/emptyenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var single)" {
  run kenvx deployment/emptyenv MYVAR=added -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added"
}

# shellcheck disable=SC2016
@test "deployment/emptyenv: exec with ENV add (new var multi)" {
  run kenvx deployment/emptyenv MYVAR="added\nmulti" -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added
multi"
}

# shellcheck disable=SC2016
@test "deployment/sample: exec with ENV multiline override" {
  run kenvx deployment/sample SAMPLE_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_MULTI"'
  assert_success
  assert_output "override
multi"
}

# shellcheck disable=SC2016
@test "deployment/sample: exec with envFrom multiline override" {
  run kenvx deployment/sample SAMPLE_FROM_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_FROM_MULTI"'
  assert_success
  assert_output "override
multi"
}

# shellcheck disable=SC2016
@test "cronjob/envfrom: exec with envFrom manifest SAMPLE_FROM_SINGLE override" {
  run kenvx cronjob/envfrom -- sh -c 'echo "$SAMPLE_FROM_SINGLE"'
  assert_success
  assert_output "override"
}

@test "cronjob/invalidrefs: prints (partial) ENV" {
  run kenvx cronjob/invalidrefs
  assert_output "SAMPLE_HERE=working"
}

@test "cronjob/duplicates: prints (partial) ENV" {
  run kenvx cronjob/duplicates
  assert_output "SAMPLE_HERE=working
SAMPLE_DUP=first_occurrence"
}

@test "deployment/sample2 -n default2: prints (partial) ENV" {
  expected="SAMPLE_SINGLE=Simple string 2
SAMPLE_MULTI=Multi line
value 2"

  run kenvx -n default2 deployment/sample2
  assert_output "$expected"

  run kenvx --namespace default2 deployment/sample2
  assert_output "$expected"
}

@test "cronjob/multicontainer: prints all ENV from all containers" {
  run kenvx cronjob/multicontainer
  assert_output "SAMPLE_FROM_CONTAINER_1=one
SAMPLE_FROM_CONTAINER_2=two
SAMPLE_FROM_INIT_CONTAINER_1=one
SAMPLE_CONTAINER_1=one
SAMPLE_CONTAINER_2=two
SAMPLE_INITCONTAINER_1=one"
}

@test "cronjob/multicontainer: limit ENV from container1" {
  run kenvx cronjob/multicontainer -c container1
  assert_output "SAMPLE_FROM_CONTAINER_1=one
SAMPLE_CONTAINER_1=one"
}

@test "cronjob/multicontainer: limit ENV from container2" {
  run kenvx cronjob/multicontainer -c container2
  assert_output "SAMPLE_FROM_CONTAINER_2=two
SAMPLE_CONTAINER_2=two"
}

@test "cronjob/multicontainer: limit ENV from init-container1" {
  run kenvx cronjob/multicontainer -c init-container1
  assert_output "SAMPLE_FROM_INIT_CONTAINER_1=one
SAMPLE_INITCONTAINER_1=one"
}

@test "cronjob/multicontainer: fails on invalid ENV from notfound container" {
  run kenvx cronjob/multicontainer -c notfound
  assert_failure
  assert_output "Error: Container 'notfound' not found in resource 'cronjob/multicontainer'"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles env vars with special chars" {
  run kenvx deployment/sample 'SPECIAL=!@#$%^&*()' -- sh -c 'echo "$SPECIAL"'
  assert_success
  assert_output "!@#$%^&*()"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles empty env vars" {
  run kenvx deployment/sample EMPTY="" -- sh -c 'echo "EMPTY=$EMPTY"'
  assert_success
  assert_output "EMPTY="
}

# shellcheck disable=SC2016
@test "deployment/sample: handles whitespace env vars" {
  run kenvx deployment/sample 'SPACE=   ' -- sh -c 'echo "SPACE=$SPACE"'
  assert_success
  assert_output "SPACE=   "
}

@test "deployment/sample2: combines namespace, container and env override" {
  run kenvx deployment/sample2 -n default2 -c pause-container SAMPLE_SINGLE=override -- sh -c 'env | grep SAMPLE_SINGLE'
  assert_success
  assert_output "SAMPLE_SINGLE=override"
}

@test "deployment/sample: accepts args in different order" {
  run kenvx -n default MYVAR=test deployment/sample -c pause-container -- env
  assert_success
}

# shellcheck disable=SC2016
@test "deployment/sample: handles multiple env overrides" {
  run kenvx deployment/sample VAR1=first VAR2=second -- sh -c 'echo "$VAR1:$VAR2"'
  assert_success
  assert_output "first:second"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles quotes in env values" {
  run kenvx deployment/sample 'QUOTED=value with "quotes"' -- sh -c 'echo "$QUOTED"'
  assert_success
  assert_output 'value with "quotes"'
}

# shellcheck disable=SC2016
@test "deployment/sample: handles long env names and values" {
  run kenvx deployment/sample "VERY_LONG_ENVIRONMENT_VARIABLE_NAME_WITH_LOTS_OF_TEXT=very_long_value_that_goes_on_and_on" -- sh -c 'echo "$VERY_LONG_ENVIRONMENT_VARIABLE_NAME_WITH_LOTS_OF_TEXT"'
  assert_success
  assert_output "very_long_value_that_goes_on_and_on"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles path-like env values" {
  run kenvx deployment/sample "PATH_VAR=/usr/local/bin:/usr/bin:/bin" -- sh -c 'echo "$PATH_VAR"'
  assert_success
  assert_output "/usr/local/bin:/usr/bin:/bin"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles equals in env values" {
  run kenvx deployment/sample 'EXPR=key1=val1,key2=val2' -- sh -c 'echo "$EXPR"'
  assert_success
  assert_output "key1=val1,key2=val2"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles url-like env values" {
  run kenvx deployment/sample "URL=https://example.com:8443" -- sh -c 'echo "$URL"'
  assert_success
  assert_output "https://example.com:8443"
}

# shellcheck disable=SC2016
@test "deployment/sample: handles json-like env values" {
  run kenvx deployment/sample 'JSON={"key":"value"}' -- sh -c 'echo "$JSON"'
  assert_success
  assert_output '{"key":"value"}'
}

# shellcheck disable=SC2016
@test "deployment/sample: handles complex structured env values" {
  run kenvx deployment/sample 'CONFIG=name=app;path=tmp;port=8080' -- sh -c 'echo "$CONFIG"'
  assert_success
  assert_output 'name=app;path=tmp;port=8080'
}
#!/usr/bin/env bats

# Using single quotes to prevent premature expansion of variables is used in the tests 
# typically to test for the expected ENV in the output command, thus lint disabled globally for this file.
# shellcheck disable=SC2016

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert # https://github.com/bats-core/bats-assert
}

kubectl-envx() {
  "$PROJECT_ROOT_DIR"/kubectl-envx "$@"
}

@test "fails on missing arguments" {
  run kubectl-envx
  assert_failure
  assert_output --partial "Error: Resource (kind/name) is required"
  assert_output --partial "Usage:"
}

@test "fails on invalid resource kind" {
  run kubectl-envx invalid/app
  assert_failure
  assert_output "error: the server doesn't have a resource type \"invalid\""
}

@test "fails on invalid resource name" {
  run kubectl-envx deployment/notfound
  assert_failure
  assert_output "Error from server (NotFound): deployments.apps \"notfound\" not found"
}

@test "fails on invalid namespace" {
  run kubectl-envx deploy/sample -n thisnamespaceisnotfound
  assert_failure
  assert_output "Error from server (NotFound): namespaces \"thisnamespaceisnotfound\" not found"
}

@test "fails on malformed env var" {
  run kubectl-envx deployment/sample "INVALID" -- env
  assert_failure
  assert_output --partial "Error: Invalid argument 'INVALID'"
}

@test "deployment/noenv: prints ENV (nothing)" {
  run kubectl-envx deployment/noenv
  assert_success
  assert_output ""
}

@test "deployment/noenv: exec with ENV" {
  run kubectl-envx deployment/noenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

@test "deployment/emptyenv: prints ENV (nothing)" {
  run kubectl-envx deployment/emptyenv
  assert_success
  assert_output ""
}

@test "deployment/emptyenv: exec with ENV" {
  run kubectl-envx deployment/emptyenv -- sh -c 'echo exec'
  assert_success
  assert_output "exec"
}

@test "deployment/emptyenv: exec with ENV add (new var single)" {
  run kubectl-envx deployment/emptyenv MYVAR=added -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added"
}

@test "deployment/emptyenv: exec with ENV add (new var multi)" {
  run kubectl-envx deployment/emptyenv MYVAR="added\nmulti" -- sh -c 'echo "$MYVAR"'
  assert_success
  assert_output "added
multi"
}

@test "deployment/sample: exec with ENV multiline override" {
  run kubectl-envx deployment/sample SAMPLE_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_MULTI"'
  assert_success
  assert_output "override
multi"
}

@test "deployment/sample: exec with envFrom multiline override" {
  run kubectl-envx deployment/sample SAMPLE_FROM_MULTI="override\nmulti" -- sh -c 'echo "$SAMPLE_FROM_MULTI"'
  assert_success
  assert_output "override
multi"
}

@test "cronjob/envfrom: exec with envFrom manifest SAMPLE_FROM_SINGLE override" {
  run kubectl-envx cronjob/envfrom -- sh -c 'echo "$SAMPLE_FROM_SINGLE"'
  assert_success
  assert_output "override"
}

@test "cronjob/invalidrefs: prints (partial) ENV" {
  run kubectl-envx cronjob/invalidrefs
  assert_success
  assert_output "SAMPLE_HERE=working"
}

@test "cronjob/duplicates: prints and exec (partial) ENV" {
  skip
  run kubectl-envx cronjob/duplicates
  assert_success
  assert_output "SAMPLE_HERE=working
SAMPLE_DUP=first_occurrence"

  run kubectl-envx cronjob/duplicates -- sh -c 'env | grep SAMPLE_ | sort'
  assert_output "SAMPLE_DUP=first_occurrence
SAMPLE_HERE=working"
}

@test "deployment/sample2 -n default2: prints (partial) ENV" {
  expected="SAMPLE_SINGLE=Simple string 2
SAMPLE_MULTI=Multi line
value 2"

  run kubectl-envx -n default2 deployment/sample2
  assert_success
  assert_output "$expected"

  run kubectl-envx --namespace default2 deployment/sample2
  assert_success
  assert_output "$expected"
}

@test "cronjob/multicontainer: prints all ENV from all containers" {
  run kubectl-envx cronjob/multicontainer
  assert_success
  assert_output "SAMPLE_FROM_CONTAINER_1=one
SAMPLE_FROM_CONTAINER_2=two
SAMPLE_FROM_INIT_CONTAINER_1=one
SAMPLE_CONTAINER_1=one
SAMPLE_CONTAINER_2=two
SAMPLE_INITCONTAINER_1=one"
}

@test "cronjob/multicontainer: limit ENV from container1" {
  run kubectl-envx cronjob/multicontainer -c container1
  assert_success
  assert_output "SAMPLE_FROM_CONTAINER_1=one
SAMPLE_CONTAINER_1=one"
}

@test "cronjob/multicontainer: limit ENV from container2" {
  run kubectl-envx cronjob/multicontainer -c container2
  assert_success
  assert_output "SAMPLE_FROM_CONTAINER_2=two
SAMPLE_CONTAINER_2=two"
}

@test "cronjob/multicontainer: limit ENV from init-container1" {
  run kubectl-envx cronjob/multicontainer -c init-container1
  assert_success
  assert_output "SAMPLE_FROM_INIT_CONTAINER_1=one
SAMPLE_INITCONTAINER_1=one"
}

@test "cronjob/multicontainer: fails on invalid ENV from notfound container" {
  run kubectl-envx cronjob/multicontainer -c notfound
  assert_failure
  assert_output "Error: Container 'notfound' not found in resource 'cronjob/multicontainer'"
}

@test "deployment/sample: handles env vars with special chars" {
  run kubectl-envx deployment/sample 'SPECIAL=!@#$%^&*()' -- sh -c 'echo "$SPECIAL"'
  assert_success
  assert_output "!@#$%^&*()"
}

@test "deployment/sample: handles empty env vars" {
  run kubectl-envx deployment/sample EMPTY="" -- sh -c 'echo "EMPTY=$EMPTY"'
  assert_success
  assert_output "EMPTY="
}

@test "deployment/sample: handles whitespace env vars" {
  run kubectl-envx deployment/sample 'SPACE=   ' -- sh -c 'echo "SPACE=$SPACE"'
  assert_success
  assert_output "SPACE=   "
}

@test "deployment/sample2: combines namespace, container and env override" {
  run kubectl-envx deployment/sample2 -n default2 -c pause-container SAMPLE_SINGLE=override -- sh -c 'env | grep SAMPLE_SINGLE'
  assert_success
  assert_output "SAMPLE_SINGLE=override"
}

@test "deployment/sample: accepts args in different order" {
  run kubectl-envx -n default MYVAR=test deployment/sample -c pause-container -- env
  assert_success
}

@test "deployment/sample: handles multiple env overrides" {
  run kubectl-envx deployment/sample VAR1=first VAR2=second -- sh -c 'echo "$VAR1:$VAR2"'
  assert_success
  assert_output "first:second"
}

@test "deployment/sample: handles quotes in env values" {
  run kubectl-envx deployment/sample 'QUOTED=value with "quotes"' -- sh -c 'echo "$QUOTED"'
  assert_success
  assert_output 'value with "quotes"'
}

@test "deployment/sample: handles long env names and values" {
  run kubectl-envx deployment/sample "VERY_LONG_ENVIRONMENT_VARIABLE_NAME_WITH_LOTS_OF_TEXT=very_long_value_that_goes_on_and_on" -- sh -c 'echo "$VERY_LONG_ENVIRONMENT_VARIABLE_NAME_WITH_LOTS_OF_TEXT"'
  assert_success
  assert_output "very_long_value_that_goes_on_and_on"
}

@test "deployment/sample: handles path-like env values" {
  run kubectl-envx deployment/sample "PATH_VAR=/usr/local/bin:/usr/bin:/bin" -- sh -c 'echo "$PATH_VAR"'
  assert_success
  assert_output "/usr/local/bin:/usr/bin:/bin"
}

@test "deployment/sample: handles equals in env values" {
  run kubectl-envx deployment/sample 'EXPR=key1=val1,key2=val2' -- sh -c 'echo "$EXPR"'
  assert_success
  assert_output "key1=val1,key2=val2"
}

@test "deployment/sample: handles url-like env values" {
  run kubectl-envx deployment/sample "URL=https://example.com:8443" -- sh -c 'echo "$URL"'
  assert_success
  assert_output "https://example.com:8443"
}

@test "deployment/sample: handles json-like env values" {
  run kubectl-envx deployment/sample 'JSON={"key":"value"}' -- sh -c 'echo "$JSON"'
  assert_success
  assert_output '{"key":"value"}'
}

@test "deployment/sample: handles complex structured env values" {
  run kubectl-envx deployment/sample 'CONFIG=name=app;path=tmp;port=8080' -- sh -c 'echo "$CONFIG"'
  assert_success
  assert_output 'name=app;path=tmp;port=8080'
}

# TODO test multi-line values tranformed to single line feature
# TODO test equals in multi-line values
# kenvx

A bash script to extract and inject Kubernetes environment variables to local commands.

- [kenvx](#kenvx)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Supported arguments](#supported-arguments)
    - [Examples](#examples)
    - [Development setup](#development-setup)


## Features

`kenvx` extracts environment variables from Kubernetes resources including those defined in `envFrom` references (ConfigMaps and Secrets). It can display these variables or use them to run local commands.

- Lists all environment variables from a Kubernetes resource
- Resolves `envFrom` references (ConfigMaps and Secrets), a typical limitation of `kubectl set env --resolve --list`.
- Supports variable overrides
- Can execute commands with the extracted variables (e.g. execute the same job locally)
- Works with any Kubernetes resource type (Pods, Deployments, StatefulSets, CronJobs, etc.)

## Requirements

`bash`, `kubectl` and `jq` must be installed.

> TODO add support matrix.

## Installation

[https://github.com/majodev/kenvx/releases](See the latest GitHub Release).

## Usage

```bash
kenvx <kind/name> [-n|--namespace <namespace>] [-c|--container <container>] [ENV_KEY=ENV_VALUE...] [-- command [args...]]
```

### Supported arguments

* `kind/name`: Kubernetes resource kind and name (required)
* `-n, --namespace`: Kubernetes namespace
* `-c, --container`: Container name
* `ENV_KEY=ENV_VALUE`: Environment variable overrides
* `-- command [args...]`: Command to run with the environment variables

### Examples

```bash
# Print all environment variables of a resource, e.g.
kenvx deployment/myapp
kenvx pod/myapp
kenvx job/myapp
kenvx cronjob/myapp
kenvx daemonset/myapp

# Print variables from specific namespace and container
kenvx deployment/myapp -n prod -c nginx

# Override variables
kenvx deployment/myapp DEBUG=true API_URL=http://localhost:8080

# Run command with variables
kenvx deployment/myapp -- env

# Use with docker (e.g. to run a local container with the extracted ENV variables)
# Note: This example uses process substitution, which is a bash feature.
# If you are using a different shell, you can save the output of `kenvx` to a file and use `--env-file` instead.
docker run --env-file <(kenvx deployment/postgres) -it alpine env
```

### Development setup

```bash
# Ensure you have docker and kind installed on your **local** host.
# This project requires kind (Kubernetes in Docker) to do the testing.

# Launch a new kind cluster on your *LOCAL* host:
brew install kind
make kind-cluster-init

# the dev container is autoconfigured to use the above kind cluster
./docker-helper --up

development@da38d91ede55:/app$ k get nodes
# NAME                  STATUS   ROLES           AGE   VERSION
# kenvx-control-plane   Ready    control-plane   25m   v1.31.4

# Runs lint and tests
development@20c533ecf4c7:/app$ make

# Run a command with the extracted environment variables from deployment/sample (see test/manifests/sample.deployment.yml)
development@da38d91ede55:/app$ kenvx deployment/sample -n default -- sh -c 'echo "# $SAMPLE_SINGLE"'
# Simple String
```
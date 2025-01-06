# kubectl-envx

A `kubectl` plugin or standalone bash script to extract and inject Kubernetes environment variables to local commands.

- [kubectl-envx](#kubectl-envx)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Supported arguments](#supported-arguments)
    - [Examples](#examples)
    - [Development setup](#development-setup)


## Features

`kubectl envx` extracts environment variables from Kubernetes resources including those defined in `envFrom` references (ConfigMaps and Secrets). It can display these variables or use them to run local commands.

- Lists all environment variables from a Kubernetes resource
- Resolves `envFrom` references (ConfigMaps and Secrets), a typical limitation of `kubectl set env --resolve --list`.
- Supports variable overrides
- Can execute commands with the extracted variables (e.g. execute the same job locally)
- Works with any Kubernetes resource type (Pods, Deployments, StatefulSets, CronJobs, etc.)

## Requirements

`bash`, `sed`, [`kubectl`](https://kubernetes.io/docs/tasks/tools/) and [`jq`](https://jqlang.github.io/jq/download/) must be installed.

The following versions of these dependencies are currently tested and supported:

| Dep         | Supported Versions           |
| ----------- | ---------------------------- |
| `kubectl`   | 1.28, 1.29, 1.30, 1.31, 1.32 |
| `jq`        | 1.6, 1.7.1                   |
| `bash`      | 5.2                          |
| (GNU) `sed` | 4.9                          |

## Installation

See the latest [GitHub Release](https://github.com/majodev/kubectl-envx/releases).

## Usage

You can use this script via `kubectl envx` (as kubectl plugin) or simply as standalone script `kubectl-envx`.

```bash
kubectl envx <kind/name> [-n|--namespace <namespace>] [-c|--container <container>] [ENV_KEY=ENV_VALUE...] [-- command [args...]]
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
kubectl envx deployment/myapp
kubectl envx pod/myapp
kubectl envx job/myapp
kubectl envx cronjob/myapp
kubectl envx daemonset/myapp

# Print variables from specific namespace and container
kubectl envx deployment/myapp -n prod -c nginx

# Override variables
kubectl envx deployment/myapp DEBUG=true API_URL=http://localhost:8080

# Run command with variables
kubectl envx deployment/myapp -- env

# Use with docker (e.g. to run a local container with the extracted ENV variables)
# Note: This example uses process substitution, which is a bash feature.
# If you are using a different shell, you can save the output of `kubectl envx` to a file and use `--env-file` instead.
docker run --env-file <(kubectl envx deployment/postgres) -it alpine env
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
NAME                         STATUS   ROLES           AGE     VERSION
kubectl-envx-control-plane   Ready    control-plane   5m33s   v1.31.4

# Runs lint and tests
development@20c533ecf4c7:/app$ make

# Runs tests for all supported dependencies (kubectl 1.xx)
development@20c533ecf4c7:/app$ make test-matrix

# Run a command with the extracted environment variables from deployment/sample (see test/manifests/sample.deployment.yml)
development@da38d91ede55:/app$ kubectl envx deployment/sample -n default -- sh -c 'echo "# $SAMPLE_SINGLE"'
# Simple String
```
# kenvx

A bash script to extract and inject Kubernetes environment variables to local commands.

- [kenvx](#kenvx)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Usage](#usage)
    - [Supported arguments](#supported-arguments)
    - [Examples](#examples)
  - [Installation](#installation)
    - [Development setup](#development-setup)


## Features

`kenvx` extracts environment variables from Kubernetes resources including those defined in `envFrom` references (ConfigMaps and Secrets). It can display these variables or use them to run local commands.

- Lists all environment variables from a Kubernetes resource
- Resolves `envFrom` references (ConfigMaps and Secrets), a typical limitation of `kubectl set env --resolve --list`.
- Supports variable overrides
- Can execute commands with the extracted variables
- Works with any Kubernetes resource type (Deployments, StatefulSets, CronJobs, etc.)

## Requirements

`bash`, `kubectl` and `jq` must be installed.

> TODO add support matrix.

## Usage

```bash
kenvx <kind/name> [-n|--namespace <namespace>] [-c|--container <container>] [ENV_KEY=ENV_VALUE...] [-- command [args...]]
```

### Supported arguments

* `kind/name`: Resource type and name (required)
* `-n, --namespace`: Kubernetes namespace
* `-c, --container`: Container name
* `ENV_KEY=ENV_VALUE`: Environment variable overrides
* `-- command [args...]`: Command to run with the environment variables

### Examples

```bash
# Print all environment variables
kenvx deployment/myapp

# Print variables from specific namespace
kenvx deployment/myapp -n prod

# Print variables from specific container
kenvx deployment/myapp -c nginx

# Override variables
kenvx deployment/myapp DEBUG=true API_URL=http://localhost:8080

# Run command with variables
kenvx deployment/myapp -- env

# Combined usage
kenvx deployment/myapp -n prod -c nginx MY_VAR=local -- ./script.sh

# Use with docker (e.g. to run a local container with the extracted ENV variables)
# Note: This example uses process substitution, which is a bash feature.
# If you are using a different shell, you can save the output of `kenvx` to a file and use `--env-file` instead.
docker run --env-file <(./kenvx deployment/app-base -c postgres) -it alpine env
```

## Installation

```bash
# Clone and install
git clone https://github.com/majodev/kenvx.git
cd kenvx
chmod +x kenvx
sudo cp kenvx /usr/local/bin/
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
```